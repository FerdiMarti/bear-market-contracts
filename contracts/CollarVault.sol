// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC4626, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

interface IOptionsProtocol {
    function createOption(
        uint8 optionType,
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

contract CollarVault is ERC4626, Ownable {
    enum OptionType { CALL, PUT }

    IERC20 public immutable collateralAsset;
    IERC20 public immutable debtAsset;
    IOptionsProtocol public immutable optionsProtocol;
    ICDPManager public immutable cdpManager;
    IPriceOracle public immutable priceOracle;

    uint256 public lastRollTime;
    uint256 public rollInterval = 90 days;
    uint256 public strikeOffsetBps = 0;
    uint256 public putStrikeOffsetBps = 1500; // 15% OTM by default
    uint256 public ivBps = 6000;

    struct WithdrawalRequest {
        address user;
        uint256 shares;
    }

    WithdrawalRequest[] public withdrawalQueue;
    mapping(address => uint256) public pendingWithdrawals;

    constructor(
        IERC20 _collateralAsset,
        IERC20 _debtAsset,
        address _cdpManager,
        address _optionsProtocol,
        address _priceOracle
    ) ERC4626(_collateralAsset) ERC20("Collar Vault Share", "CVS") Ownable(msg.sender) {
        collateralAsset = _collateralAsset;
        debtAsset = _debtAsset;
        cdpManager = ICDPManager(_cdpManager);
        optionsProtocol = IOptionsProtocol(_optionsProtocol);
        priceOracle = IPriceOracle(_priceOracle);
    }

    function setRollInterval(uint256 newInterval) external onlyOwner {
        require(newInterval >= 1 days && newInterval <= 365 days, "Invalid interval");
        rollInterval = newInterval;
    }

    function setStrikeOffsetBps(uint256 newOffset) external onlyOwner {
        require(newOffset <= 1000, "Offset too large");
        strikeOffsetBps = newOffset;
    }

    function setPutStrikeOffsetBps(uint256 newOffset) external onlyOwner {
        require(newOffset >= 100 && newOffset <= 5000, "Invalid put offset");
        putStrikeOffsetBps = newOffset;
    }

    function setIvBps(uint256 newIvBps) external onlyOwner {
        require(newIvBps >= 1000 && newIvBps <= 10000, "IV out of bounds");
        ivBps = newIvBps;
    }

    function _afterDeposit(uint256 assets) internal {
        collateralAsset.approve(address(cdpManager), assets);
        cdpManager.depositCollateral(address(collateralAsset), assets);
        uint256 borrowAmount = (assets * 1e18) / 150e16;
        cdpManager.borrow(address(debtAsset), borrowAmount);
    }

    function _writeStrategy(uint256 callAmount, uint256 maxPutCost) internal {
        uint256 spot = priceOracle.getPrice();
        uint256 callStrike = (spot * (10000 + strikeOffsetBps)) / 10000;
        uint256 putStrike = (spot * (10000 - putStrikeOffsetBps)) / 10000;
        uint256 expiry = block.timestamp + rollInterval;
        uint256 T = rollInterval / 365 days;

        uint256 callPremium = _blackScholesPrice(OptionType.CALL, spot, callStrike, T, ivBps);
        uint256 putPremium = _blackScholesPrice(OptionType.PUT, spot, putStrike, T, ivBps);

        if (collateralAsset.allowance(address(this), address(optionsProtocol)) < callAmount) {
            collateralAsset.approve(address(optionsProtocol), type(uint256).max);
        }
        if (debtAsset.allowance(address(this), address(optionsProtocol)) < maxPutCost) {
            debtAsset.approve(address(optionsProtocol), type(uint256).max);
        }

        optionsProtocol.createOption(0, address(collateralAsset), callStrike, expiry, callPremium, callAmount, address(debtAsset));
        optionsProtocol.createOption(1, address(collateralAsset), putStrike, expiry, putPremium, maxPutCost, address(debtAsset));
    }

    function rolloverCollar() external {
        require(block.timestamp >= lastRollTime + rollInterval, "Too early");
        lastRollTime = block.timestamp;

        collectPremiums();

        uint256 callCollateral = collateralAsset.balanceOf(address(this));
        uint256 putBudget = debtAsset.balanceOf(address(this));

        _writeStrategy(callCollateral, putBudget);
    }

    function collectPremiums() public {
        optionsProtocol.claimPremiums(address(this));
    }

    function _blackScholesPrice(
        OptionType,
        uint256 spot,
        uint256,
        uint256 timeToExpiry,
        uint256 ivBpsInput
    ) internal pure returns (uint256) {
        uint256 iv = (spot * ivBpsInput) / 10000;
        uint256 sqrtT = Math.sqrt(timeToExpiry * 1e18);
        uint256 premium = (iv * sqrtT) / 1e9;
        return premium;
    }

    function afterDeposit(uint256 assets, uint256) internal {
        _afterDeposit(assets);
    }

    function requestWithdrawal(uint256 shares) external {
        require(shares > 0, "Zero shares");
        _transfer(msg.sender, address(this), shares);
        withdrawalQueue.push(WithdrawalRequest({ user: msg.sender, shares: shares }));
        pendingWithdrawals[msg.sender] += shares;
    }

    function claimWithdrawal() external {
        uint256 shares = pendingWithdrawals[msg.sender];
        require(shares > 0, "No shares to withdraw");

        uint256 assetsToWithdraw = previewRedeem(shares);
        _burn(address(this), shares);
        pendingWithdrawals[msg.sender] = 0;

        collateralAsset.transfer(msg.sender, assetsToWithdraw);
    }
}
