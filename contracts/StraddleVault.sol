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

    }

    function _writeStraddle(uint256 callAmount, uint256 putAmount) internal {

    }

    function rolloverStraddles() external {

    }

    function collectPremiums() public {

    }

    // Simplified Black-Scholes premium approximation
    function _blackScholesPrice(
        OptionType optionType,
        uint256 spot,
        uint256 strike,
        uint256 timeToExpiry,
        uint256 ivBps
    ) internal pure returns (uint256) {

    }

    function afterDeposit(uint256 assets, uint256) internal override {
        _afterDeposit(assets);
    }

    // Queued withdrawal system
    function requestWithdrawal(uint256 shares) external {

    }

    function processWithdrawals() external onlyOwner {

    }
}
