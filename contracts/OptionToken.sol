// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

enum OptionType {
    CALL,
    PUT
}

//European Style Option Token
//Cash settlement
contract OptionToken is ERC20, Ownable, ERC20Burnable, ReentrancyGuard {
    OptionType public optionType;
    string public pythAssetId;
    uint256 public strikePrice;
    uint256 public expiration;
    uint256 public premium;
    uint256 public collateral;
    uint256 public totalSold;
    uint256 public executionPrice;
    bool public priceFixed;
    bool public isFullyExecuted;
    IERC20 public paymentToken;
    
    event OptionExecuted(address indexed executor, uint256 payout, uint256 burnedAmount);
    event OptionPurchased(address indexed buyer, uint256 amount);
    event UnsoldTokensBurned(address indexed owner, uint256 amount, uint256 collateralReturned);
    event ExecutionPriceFixed(uint256 price);
    
    modifier onlyBeforeExpiration() {
        require(block.timestamp < expiration, "Option has expired");
        _;
    }
    
    modifier onlyAfterExpiration() {
        require(block.timestamp >= expiration, "Option has not expired yet");
        require(block.timestamp <= expiration + 1 days, "Execution period has ended");
        _;
    }
    
    modifier onlyNotFullyExecuted() {
        require(!isFullyExecuted, "Option has been fully executed");
        _;
    }
    
    constructor(
        OptionType _optionType,
        string memory _pythAssetId,
        uint256 _strikePrice,
        uint256 _expiration,
        uint256 _premium,
        uint256 _amount,
        address _paymentToken
    ) 
        ERC20(string.concat("Option-", _pythAssetId),"OPT")
        Ownable(msg.sender)
    {
        optionType = _optionType;
        pythAssetId = _pythAssetId;
        strikePrice = _strikePrice;
        expiration = _expiration;
        premium = _premium;
        paymentToken = IERC20(_paymentToken);
        
        // Calculate collateral based on current asset price
        uint256 currentPrice = getAssetPrice();
        collateral = currentPrice * _amount;
        
        // Mint tokens to the contract itself
        _mint(address(this), _amount);
    }
    
    // Dummy function to simulate oracle price feed
    function getAssetPrice() public view returns (uint256) {
        // In a real implementation, this would call the Pyth oracle
        // For now, we'll return a dummy price
        return 1000; // Dummy price of 1000
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
        
        emit UnsoldTokensBurned(owner(), amount, collateralToReturn);
    }
    
    function executeOption() external onlyAfterExpiration onlyNotFullyExecuted nonReentrant {
        uint256 holderBalance = balanceOf(msg.sender);
        require(holderBalance > 0, "No tokens to execute");
        
        uint256 currentPrice;
        if (!priceFixed) {
            currentPrice = getAssetPrice();
            executionPrice = currentPrice;
            priceFixed = true;
            emit ExecutionPriceFixed(currentPrice);
        } else {
            currentPrice = executionPrice;
        }
        
        uint256 payout = 0;
        
        if (optionType == OptionType.CALL) {
            if (currentPrice > strikePrice) {
                // Calculate payout based on holder's share of total supply
                uint256 priceDifference = currentPrice - strikePrice;
                payout = (priceDifference * holderBalance * collateral) / (totalSupply() * currentPrice);
            }
        } else { // PUT
            if (currentPrice < strikePrice) {
                // Calculate payout based on holder's share of total supply
                uint256 priceDifference = strikePrice - currentPrice;
                payout = (priceDifference * holderBalance * collateral) / (totalSupply() * currentPrice);
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
        
        // Check if all tokens have been executed
        if (totalSupply() == 0) {
            isFullyExecuted = true;
        }
    }
}