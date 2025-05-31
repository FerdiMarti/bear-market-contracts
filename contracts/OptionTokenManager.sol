// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./OptionToken.sol";

contract OptionTokenManager is Ownable {
    uint32 public constant MIN_EXECUTION_WINDOW_SIZE = 10 minutes;
    address public immutable pythAddress;
    mapping(address => bool) public isOptionToken;
    address[] public deployedOptions;

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

    constructor(address _pythAddress) Ownable(msg.sender) {
        require(_pythAddress != address(0), "Invalid Pyth address");
        pythAddress = _pythAddress;
    }

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
    ) external returns (address) {
        require(expiration > block.timestamp, "Expiration must be in the future");
        require(executionWindowSize > MIN_EXECUTION_WINDOW_SIZE, "Execution window must be greater than 10 minutes");
        require(premium > 0, "Premium must be greater than 0");
        require(amount > 0, "Amount must be greater than 0");
        require(paymentToken != address(0), "Invalid payment token address");
        require(collateral > 0, "Collateral must be greater than 0");

        OptionToken newOptionToken = new OptionToken(
            optionType,
            paymentTokenPythAssetId,
            pythAddress,
            strikePrice,
            expiration,
            executionWindowSize,
            premium,
            amount,
            paymentToken,
            collateral
        );

        address optionTokenAddress = address(newOptionToken);
        isOptionToken[optionTokenAddress] = true;
        deployedOptions.push(optionTokenAddress);

        emit OptionTokenDeployed(
            optionTokenAddress,
            optionType,
            strikePrice,
            expiration,
            executionWindowSize,
            premium,
            amount,
            paymentToken,
            collateral
        );

        return optionTokenAddress;
    }

    function getDeployedOptions() external view returns (address[] memory) {
        return deployedOptions;
    }

    function getDeployedOptionsCount() external view returns (uint256) {
        return deployedOptions.length;
    }
} 