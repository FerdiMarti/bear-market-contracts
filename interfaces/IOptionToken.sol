// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum OptionType {
    CALL,
    PUT
}

interface IOptionToken is IERC20 {
    // Events
    event OptionExecuted(address indexed executor, uint256 payout, uint256 burnedAmount);
    event OptionPurchased(address indexed buyer, uint256 amount);
    event UnsoldTokensBurned(address indexed owner, uint256 amount, uint256 collateralReturned);
    event ExecutionPriceFixed(uint256 price);
    event FullyExecuted();

    // State variables
    function optionType() external view returns (OptionType);
    function pythAssetId() external view returns (bytes32);
    function pythAddress() external view returns (address);
    function startPrice() external view returns (uint256);
    function strikePrice() external view returns (uint256);
    function expiration() external view returns (uint256);
    function executionWindowSize() external view returns (uint256);
    function premium() external view returns (uint256);
    function collateral() external view returns (uint256);
    function totalSold() external view returns (uint256);
    function executionPrice() external view returns (uint256);
    function priceFixed() external view returns (bool);
    function isFullyExecuted() external view returns (bool);
    function paymentToken() external view returns (IERC20);

    // Functions
    function purchaseOption(uint256 amount) external;
    function burnUnsoldTokens(uint256 amount) external;
    function fixPrice() external;
    function executeOption() external;
} 