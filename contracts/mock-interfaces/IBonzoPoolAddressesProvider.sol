// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBonzoPoolAddressesProvider {
    function getPool() external view returns (address);
} 