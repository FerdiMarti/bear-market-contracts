// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOptionTokenManager {
    enum OptionType {
        CALL,
        PUT
    }

    event OptionTokenDeployed(
        address indexed optionToken,
        OptionType optionType,
        uint256 strikePrice,
        uint256 expiration,
        uint256 executionWindowSize,
        uint256 premium,
        uint256 amount,
        address paymentToken,
        uint256 collateral
    );

    function MIN_EXECUTION_WINDOW_SIZE() external view returns (uint32);
    function pythAddress() external view returns (address);
    function isOptionToken(address) external view returns (bool);
    function deployedOptions(uint256) external view returns (address);

    function deployOptionToken(
        OptionType optionType,
        bytes32 paymentTokenPythAssetId,
        uint256 strikePrice,
        uint256 expiration,
        uint256 executionWindowSize,
        uint256 premium,
        uint256 amount,
        address paymentToken,
        uint256 collateral
    ) external returns (address);

    function getDeployedOptions() external view returns (address[] memory);
    function getDeployedOptionsCount() external view returns (uint256);
} 