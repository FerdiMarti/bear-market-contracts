// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IOptionsProtocol {
    function createOption(
        uint8 optionType, // 0 = CALL, 1 = PUT
        address underlying,
        uint256 strikePrice,
        uint256 expiration,
        uint256 premium,
        uint256 amount,
        address paymentToken
    ) external returns (address option);

    function claimPremiums(address recipient) external returns (uint256);
}

interface ICDPManager {
    function depositCollateral(address collateralAsset, uint256 amount) external;
    function borrow(address debtAsset, uint256 amount) external;
    function repay(address debtAsset, uint256 amount) external;
    function withdrawCollateral(address collateralAsset, uint256 amount) external;
}

interface IPriceOracle {
    function getPrice() external view returns (uint256);
}

contract StraddleVault is ERC4626, Ownable {
    enum OptionType { CALL, PUT }

    IERC20 public immutable collateralAsset;
    IERC20 public immutable debtAsset;
    IOptionsProtocol public immutable optionsProtocol;
    ICDPManager public immutable cdpManager;
    IPriceOracle public immutable priceOracle;

    uint256 public lastRollTime;
    uint256 public constant ROLL_INTERVAL = 90 days;
    uint256 public constant STRIKE_OFFSET_BPS = 0; // ATM
    uint256 public constant IV_BPS = 6000; // 60% implied volatility

    struct WithdrawalRequest {
        address user;
        uint256 shares;
    }

    WithdrawalRequest[] public withdrawalQueue;

    constructor(
        IERC20 _collateralAsset,
        IERC20 _debtAsset,
        address _cdpManager,
        address _optionsProtocol,
        address _priceOracle
    ) ERC4626(_collateralAsset) ERC20("Straddle Vault Share", "SVS") Ownable(msg.sender) {
        collateralAsset = _collateralAsset;
        debtAsset = _debtAsset;
        cdpManager = ICDPManager(_cdpManager);
        optionsProtocol = IOptionsProtocol(_optionsProtocol);
        priceOracle = IPriceOracle(_priceOracle);
    }

    function _afterDeposit(uint256 assets) internal {
        collateralAsset.approve(address(cdpManager), assets);
        cdpManager.depositCollateral(address(collateralAsset), assets);

        // Borrow NECT (debtAsset) based on fixed 150% CR
        uint256 borrowAmount = (assets * 1e18) / 150e16; // e.g., 66.66% of value
        cdpManager.borrow(address(debtAsset), borrowAmount);
    }

    function _writeStraddle(uint256 callAmount, uint256 putAmount) internal {
        uint256 strike = priceOracle.getPrice();
        uint256 expiry = block.timestamp + ROLL_INTERVAL;
        uint256 T = ROLL_INTERVAL / 365 days; // time to expiry in years (approx 0.25)

        uint256 callPremium = _blackScholesPrice(OptionType.CALL, strike, strike, T, IV_BPS);
        uint256 putPremium = _blackScholesPrice(OptionType.PUT, strike, strike, T, IV_BPS);

        collateralAsset.approve(address(optionsProtocol), callAmount);
        debtAsset.approve(address(optionsProtocol), putAmount);

        optionsProtocol.createOption(0, address(collateralAsset), strike, expiry, callPremium, callAmount, address(debtAsset));
        optionsProtocol.createOption(1, address(collateralAsset), strike, expiry, putPremium, putAmount, address(debtAsset));
    }

    function rolloverStraddles() external {
        require(block.timestamp >= lastRollTime + ROLL_INTERVAL, "Too early");
        lastRollTime = block.timestamp;

        collectPremiums(); // Auto-compound premiums before new round

        uint256 callCollateral = collateralAsset.balanceOf(address(this));
        uint256 putCollateral = debtAsset.balanceOf(address(this));

        _writeStraddle(callCollateral, putCollateral);
    }

    function collectPremiums() public {
        uint256 collected = optionsProtocol.claimPremiums(address(this));
        // Premiums stay in contract and are reused in next rollover
    }

    // Simplified Black-Scholes premium approximation
    function _blackScholesPrice(
        OptionType optionType,
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 ivBps
    ) internal pure returns (uint256) {
        // Basic proportional premium = spot * iv * sqrt(T)
        // ivBps is in basis points (e.g., 6000 = 60%)

        uint256 iv = (spot * ivBps) / 10000;
        uint256 sqrtT = Math.sqrt(timeToExpiry * 1e18); // simplified
        uint256 premium = (iv * sqrtT) / 1e9; // adjust back to 1e18 scale

        return premium;
    }

    function afterDeposit(uint256 assets, uint256) internal override {
        _afterDeposit(assets);
    }

    // Queued withdrawal system
    function requestWithdrawal(uint256 shares) external {
        require(shares > 0, "Zero shares");
        _transfer(msg.sender, address(this), shares);
        withdrawalQueue.push(WithdrawalRequest({ user: msg.sender, shares: shares }));
    }

    function processWithdrawals() external onlyOwner {
        for (uint256 i = 0; i < withdrawalQueue.length; i++) {
            WithdrawalRequest memory req = withdrawalQueue[i];
            uint256 assetsToWithdraw = previewRedeem(req.shares);
            _burn(address(this), req.shares);
            collateralAsset.transfer(req.user, assetsToWithdraw);
        }
        delete withdrawalQueue;
    }
}
