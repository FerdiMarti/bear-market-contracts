// SPDX-License-Identifier: MIT
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IOptionToken } from "../interfaces/IOptionToken.sol";

pragma solidity ^0.8.0;

//Helper contract to force hardhat to compile types
interface TypeIntegrations is IERC20, IOptionToken {
} 