# Bear Market Contracts

This repository contains the smart contracts for the Bear Market protocol, a decentralized options trading platform built for EVM.

## Overview

The Bear Market protocol enables users to trade options with yield-bearing underlying assets. The system consists of several key components:

- `OptionToken.sol`: The main options token contract - inherits ERC20
- `YieldBearingOptionToken.sol`: Implementation for yield-bearing options
- `OptionTokenManager.sol`: Manager contract for handling option token deployment
- `beraborrow/`: Integration startegies for Beraborrow protocol

## Beraborrow specific Readmes

Find specific readmes for the Beraborrow contracts in contracts/beraborrow/

## Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Hardhat

## Installation

```bash
# Install dependencies
npm install
```

## Development

```bash
# Compile contracts
npx hardhat compile

# Run tests
npx hardhat test

# Deploy to local network
npx hardhat node
npx hardhat run scripts/deploy-option-token-manager.ts --network localhost
```

## Available Scripts

- `npm run getusd`: Get USDC on local network
- `npm run checkusd`: Check USDC balance on local network
- `npm run deploymanager`: Deploy the option token manager
- `npm run copytypes`: Copy type definitions to frontend project

## Contract Addresses

### Hedera Testnet

- OptionTokenManager: `0x46162F67d1451002EBa091468cFA0AaAAca24a00`

### Berachain mainnet

- OptionTokenManager: `0x145C87Aeb313C706Be153dF868b7e8B799dd1a79`
- CollarVault: `0xb36e947059ECD2ec03A48c1D547866cb79BcC5ef`
- LSPAllocator: `0x3E6AC6064C83F741E6cB7e3633AccC661a40B948`

## Architecture

The protocol is built using:

- Solidity for smart contracts
- Hardhat for development environment
- OpenZeppelin for standard contract implementations
- Pyth Network for price feeds
- Example implementation with Bonzo Finance yield protocol on Hedera
