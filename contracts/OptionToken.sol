// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

enum OptionType {
    CALL,
    PUT
}

//European Style Option Token
//Cash settlement
contract OptionToken is ERC20, Ownable, ERC20Burnable, ReentrancyGuard {
    OptionType public optionType;
    IERC20 public paymentToken;
    bytes32 public paymentTokenPythAssetId;
    address public pythAddress;
    uint256 public startPrice; //price at which the option was created; Just for informative purposes
    uint256 public strikePrice;
    uint256 public expiration;
    uint256 public executionWindowSize; // Time window for execution in seconds
    uint256 public premium;
    uint256 public collateral;
    uint256 public totalSold;
    uint256 public executionPrice;
    bool public priceFixed;
    bool public isFullyExecuted;
    
    event OptionExecuted(address indexed executor, uint256 payout, uint256 burnedAmount);
    event OptionPurchased(address indexed buyer, uint256 amount);
    event UnsoldTokensBurned(address indexed owner, uint256 amount, uint256 collateralReturned);
    event ExecutionPriceFixed(uint256 price);
    event FullyExecuted();
    
    modifier onlyBeforeExpiration() {
        require(block.timestamp < expiration, "Option has expired");
        _;
    }
    
    modifier onlyDuringExecutionWindow() {
        require(block.timestamp >= expiration, "Option has not expired yet");
        require(block.timestamp <= expiration + executionWindowSize, "Execution period has ended");
        _;
    }
    
    modifier onlyNotFullyExecuted() {
        require(!isFullyExecuted, "Option has been fully executed");
        _;
    }
    
    constructor(
        OptionType _optionType,
        bytes32 _paymentTokenPythAssetId,
        address _pythAddress,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _executionWindowSize, // Time window for execution in seconds
        uint256 _premium,
        uint256 _amount,
        address _paymentToken,
        uint256 _collateral //minter decides how much collateral is used overall, capping the payout per token
    ) 
        ERC20("Roin Option","rOPT")
        Ownable(msg.sender)
    {
        optionType = _optionType;
        paymentTokenPythAssetId = _paymentTokenPythAssetId;
        pythAddress = _pythAddress;
        strikePrice = _strikePrice;
        expiration = _expiration;
        executionWindowSize = _executionWindowSize;
        premium = _premium;
        paymentToken = IERC20(_paymentToken);
        
        // Set collateral and start price
        startPrice = _getAssetPrice();
        collateral = _collateral;

        //minimum collateral is 1x start price per token
        require(collateral >= startPrice * _amount, "Collateral must be at least 1x start price per token");
        
        //Check for valid strike price
        if (optionType == OptionType.CALL) {
            require(strikePrice >= startPrice, "strike price must be at least start price for CALL");
        } else {
            require(strikePrice <= startPrice, "strike price must be at most start price for PUT");
        }
        
        // Mint tokens to the contract itself
        _mint(address(this), _amount);
    }
    
    function purchaseOption(uint256 amount) external onlyBeforeExpiration {
        require(balanceOf(address(this)) >= amount, "Insufficient option tokens available");
        
        // Transfer premium to owner
        require(
            paymentToken.transferFrom(msg.sender, owner(), premium * amount),
            "Premium transfer failed"
        );
        
        // Transfer option tokens to buyer
        _transfer(address(this), msg.sender, amount);
        totalSold += amount;
        
        emit OptionPurchased(msg.sender, amount);
    }
    
    function burnUnsoldTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(address(this)) >= amount, "Insufficient unsold tokens to burn");
        
        // Calculate collateral to return based on proportion of tokens being burned
        uint256 collateralToReturn = (amount * collateral) / totalSupply();
        
        // Burn the specified amount of tokens
        _burn(address(this), amount);
        
        // Return the proportional collateral to the owner
        require(
            paymentToken.transfer(owner(), collateralToReturn),
            "Collateral return failed"
        );

        // Burning could also happen after all tokens are executed if there was a leftover
        // so we need to check if all tokens have been executed
        _checkFullyExecuted();
        
        emit UnsoldTokensBurned(owner(), amount, collateralToReturn);
    }

    function fixPrice() external {
        _fixPrice();
    }
    
    function executeOption() external onlyDuringExecutionWindow onlyNotFullyExecuted nonReentrant {
        uint256 holderBalance = balanceOf(msg.sender);
        require(holderBalance > 0, "No tokens to execute");
        
        _fixPrice();
        uint256 currentPrice = executionPrice;
        uint256 payout = 0;
        
        if (optionType == OptionType.CALL) {
            if (currentPrice > strikePrice) {
                // Calculate payout based on holder's share of total supply
                uint256 priceDifference = currentPrice - strikePrice;
                uint256 maxPayoutPerToken = collateral / totalSupply(); // Maximum payout per token
                uint256 calculatedPayout = (priceDifference * holderBalance * collateral) / (totalSupply() * currentPrice);
                
                // Cap the payout at the maximum per token
                payout = calculatedPayout > (maxPayoutPerToken * holderBalance) ? 
                    maxPayoutPerToken * holderBalance : calculatedPayout;
            }
        } else { // PUT
            if (currentPrice < strikePrice) {
                // Calculate payout based on holder's share of total supply
                uint256 priceDifference = strikePrice - currentPrice;
                uint256 maxPayoutPerToken = collateral / totalSupply(); // Maximum payout per token
                uint256 calculatedPayout = (priceDifference * holderBalance * collateral) / (totalSupply() * currentPrice);
                
                // Cap the payout at the maximum per token
                payout = calculatedPayout > (maxPayoutPerToken * holderBalance) ? 
                    maxPayoutPerToken * holderBalance : calculatedPayout;
            }
        }
        
        if (payout > 0) {
            // Transfer payout to option holder
            require(
                paymentToken.transfer(msg.sender, payout),
                "Payout transfer failed"
            );
        }
        
        // Burn the holder's tokens
        _burn(msg.sender, holderBalance);
        
        emit OptionExecuted(msg.sender, payout, holderBalance);

        _checkFullyExecuted();
    }

    function _checkFullyExecuted() internal {
        if (totalSupply() == 0) {
            isFullyExecuted = true;
            emit FullyExecuted();
        }
    }

    // Get the current price of the asset from Pyth
    function _getAssetPrice() internal view returns (uint256) {
        IPyth pyth = IPyth(pythAddress);
        PythStructs.Price memory currentBasePrice = pyth.getPriceUnsafe(paymentTokenPythAssetId);
        int64 price = currentBasePrice.price;
        require(price > 0, "Invalid price from Oracle");

        //convert to payment token decimals
        uint8 paymentDecimals = IERC20Metadata(address(paymentToken)).decimals();
        int32 expo = currentBasePrice.expo;
        int32 scaleFactor = int32(uint32(paymentDecimals)) - (-expo);
        uint256 priceInPaymentDecimals = uint256(uint64(price)) * uint256(10 ** uint32(scaleFactor));

        return priceInPaymentDecimals;
    }

    function _fixPrice() internal onlyDuringExecutionWindow onlyNotFullyExecuted nonReentrant {
        if (priceFixed) return;
        executionPrice = _getAssetPrice();
        priceFixed = true;
        emit ExecutionPriceFixed(executionPrice);
    }
}