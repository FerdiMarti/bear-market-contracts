# **CollarVault**

An ERC4626-compliant vault that manages a Beraborrow CDP and continuously writes delta-hedged collars using an integrated options protocol Bear Market to earn passive income for Liquidity Providers (LPs). Designed for high capital efficiency, yield generation, and automated compounding for LPs.

## Overview

CollarVault automates a structured yield strategy:

- Depositors provide stETH collateral.

- The vault opens a CDP on Beraborrow and borrows $NECT.

- It writes covered CALLs and buys Out of the Money (OTM) PUTs on ETH.

- Every 30 days, premiums are auto-compounded to write new straddles.

- Withdrawals are queued and processed after rollovers, matching the strategy's long-term orientation.

- All collateral backing options continues to earn yield via integrated lending, amplifying returns without additional action from the vault.

## **Architecture**

`[User Deposit (stETH)]`  
 `↓`  
`[CDP Manager: Borrow $NECT]`  
 `↓`  
`[Write Covered CALL (ETH) + buy OTM PUT]`  
 `↓`  
`[Earn Premium]`  
 `↓`  
`[Idle Capital Deployed in Lending Pool]`  
 `↓`  
`[Earn Yield]`  
 `↓`  
`[Auto-Compound at Roll Interval (30d)]`  
 `↓`  
`[Vault Grows in Value]`

- Fully ERC4626-compliant.

- Uses a simplified Black-Scholes pricing model for fair option pricing.

- Vault shares reflect pro-rata claim on growing strategy yield.

See diagram in the ETHGlobal submission for a full architecture overview of this vault strategy

## **Key Features**

This Managed Leveraged Vault (MLV) strategy is built using the ERC4626 interface, allowing users to deposit assets and receive vault shares that represent their proportional ownership. At its core, the vault executes a delta-neutral options strategy by combining a covered CALL with a protective out-of-the-money PUT, effectively reducing directional risk.

Options positions are rolled over every 30 days by default (this interval can be adjusted by the vault owner), ensuring the strategy remains active and responsive to market dynamics. Premiums collected from each options cycle are automatically reinvested, compounding returns for vault participants without requiring user intervention.

To maintain liquidity and strategy integrity, user withdrawals are queued and processed only after an options cycle has expired. This aligns withdrawal timing with the strategy’s capital commitment periods. Additionally, the vault uses a simplified Black-Scholes pricing model directly on-chain to determine option premiums, removing the need for external computation.

Designed for efficiency, the contract includes gas optimizations such as batched processing, pre-approved allowances, and minimized state changes, making it suitable for repeated execution without significant overhead.

Example Flow

1. Alice deposits 10 ETH @$2,500 and receives `x` vault shares
2. Vault opens CDP, borrows $12,500 ETH worth of $NECT
3. Vault writes:
    - Covered CALL (backed by ETH)
4. Vault buys:
    - OTM Put on ETH
5. Vault collects premiums
6. Bear Market Options Protocol lends out idle capital while waiting for option expiry
7. 30 days later:
    - Vault reinvests into next straddle
    - Collects yield from lending protocols
    - Pays out any potential losses
8. Alice requests withdrawal → processed after next expiry

## **Contracts**

| Contract            | Description                     |
| ------------------- | ------------------------------- |
| `StraddleVault.sol` | Main ERC4626 vault logic        |
| `IOptionsProtocol`  | Interface to your options dApp  |
| `ICDPManager`       | Interface to Beraborrow CDP     |
| `IPriceOracle`      | Oracle abstraction (e.g., Pyth) |

## Security & Risk Notes

To maintain the solvency of the vault, a withdrawal queue mechanism is implemented. Rather than allowing immediate redemptions, users request withdrawals which are then processed after the current options cycle concludes. While this approach requires patience from participants, it ensures the strategy can remain fully deployed throughout each cycle without risking forced liquidations or capital inefficiencies.

In the event of a critical failure — such as a malfunctioning price oracle or issues with a connected external protocol — the vault includes a pause mechanism. This allows the contract owner to temporarily halt deposits, withdrawals, and rollovers, protecting user funds until normal operations can resume.

To allow for some degree of flexibility while maintaining risk controls, key strategy parameters such as implied volatility (IV) assumptions and the rollover interval are configurable by the vault owner. These adjustments are bounded within predefined limits to prevent abuse or over-exposure.

Importantly, the vault does not use leverage beyond what is permitted by the underlying CDP (Collateralized Debt Position) manager. This means that the protocol’s risk profile is directly tied to the collateralization requirements of the lending system and avoids taking on external or excessive leverage.

## Future Improvements

One area of potential enhancement is the introduction of an automated dynamic strike offset based on market conditions. Currently, strike prices are computed based on a fixed basis with manual strike offset available for the vault manager. point offset from spot, but in the future, this could be made adaptive, responding to changing volatility regimes or market skew to optimize returns.

The current implementation is designed with a single collateral asset, such as ETH or stETH. Future versions may support multi-collateral strategies, including assets like BTC or even stablecoins, broadening the appeal of the vault and diversifying its risk exposure.

Lastly, integrating with real-time volatility oracles would allow the vault to dynamically calibrate its implied volatility assumptions. Instead of relying on a static IV parameter, the system could react to market data in real time, improving option pricing accuracy and potentially enhancing yield while maintaining appropriate risk coverage.

# **CollarVault**

An ERC4626-compliant vault that manages a Beraborrow CDP and continuously writes delta-hedged collars using an integrated options protocol Bear Market to earn passive income for Liquidity Providers (LPs). Designed for high capital efficiency, yield generation, and automated compounding for LPs.

## Overview

CollarVault automates a structured yield strategy:

- Depositors provide stETH collateral.

- The vault opens a CDP on Beraborrow and borrows $NECT.

- It writes covered CALLs and buys Out of the Money (OTM) PUTs on ETH.

- Every 30 days, premiums are auto-compounded to write new straddles.

- Withdrawals are queued and processed after rollovers, matching the strategy's long-term orientation.

- All collateral backing options continues to earn yield via integrated lending, amplifying returns without additional action from the vault.

## **Architecture**

`[User Deposit (stETH)]`  
 `↓`  
`[CDP Manager: Borrow $NECT]`  
 `↓`  
`[Write Covered CALL (ETH) + buy OTM PUT]`  
 `↓`  
`[Earn Premium]`  
 `↓`  
`[Idle Capital Deployed in Lending Pool]`  
 `↓`  
`[Earn Yield]`  
 `↓`  
`[Auto-Compound at Roll Interval (30d)]`  
 `↓`  
`[Vault Grows in Value]`

- Fully ERC4626-compliant.

- Uses a simplified Black-Scholes pricing model for fair option pricing.

- Vault shares reflect pro-rata claim on growing strategy yield.

See below diagram for a full architecture overview of this vault strategy:

## **Key Features**

This Managed Leveraged Vault (MLV) strategy is built using the ERC4626 interface, allowing users to deposit assets and receive vault shares that represent their proportional ownership. At its core, the vault executes a delta-neutral options strategy by combining a covered CALL with a protective out-of-the-money PUT, effectively reducing directional risk.

Options positions are rolled over every 30 days by default (this interval can be adjusted by the vault owner), ensuring the strategy remains active and responsive to market dynamics. Premiums collected from each options cycle are automatically reinvested, compounding returns for vault participants without requiring user intervention.

To maintain liquidity and strategy integrity, user withdrawals are queued and processed only after an options cycle has expired. This aligns withdrawal timing with the strategy’s capital commitment periods. Additionally, the vault uses a simplified Black-Scholes pricing model directly on-chain to determine option premiums, removing the need for external computation.

Designed for efficiency, the contract includes gas optimizations such as batched processing, pre-approved allowances, and minimized state changes, making it suitable for repeated execution without significant overhead.

Example Flow

1. Alice deposits 10 ETH @$2,500 and receives `x` vault shares
2. Vault opens CDP, borrows $12,500 ETH worth of $NECT
3. Vault writes:
    - Covered CALL (backed by ETH)
4. Vault buys:
    - OTM Put on ETH
5. Vault collects premiums
6. Bear Market Options Protocol lends out idle capital while waiting for option expiry
7. 30 days later:
    - Vault reinvests into next straddle
    - Collects yield from lending protocols
    - Pays out any potential losses
8. Alice requests withdrawal → processed after next expiry

## **Contracts**

| Contract            | Description                     |
| ------------------- | ------------------------------- |
| `StraddleVault.sol` | Main ERC4626 vault logic        |
| `IOptionsProtocol`  | Interface to your options dApp  |
| `ICDPManager`       | Interface to Beraborrow CDP     |
| `IPriceOracle`      | Oracle abstraction (e.g., Pyth) |

## Security & Risk Notes

To maintain the solvency of the vault, a withdrawal queue mechanism is implemented. Rather than allowing immediate redemptions, users request withdrawals which are then processed after the current options cycle concludes. While this approach requires patience from participants, it ensures the strategy can remain fully deployed throughout each cycle without risking forced liquidations or capital inefficiencies.

In the event of a critical failure — such as a malfunctioning price oracle or issues with a connected external protocol — the vault includes a pause mechanism. This allows the contract owner to temporarily halt deposits, withdrawals, and rollovers, protecting user funds until normal operations can resume.

To allow for some degree of flexibility while maintaining risk controls, key strategy parameters such as implied volatility (IV) assumptions and the rollover interval are configurable by the vault owner. These adjustments are bounded within predefined limits to prevent abuse or over-exposure.

Importantly, the vault does not use leverage beyond what is permitted by the underlying CDP (Collateralized Debt Position) manager. This means that the protocol’s risk profile is directly tied to the collateralization requirements of the lending system and avoids taking on external or excessive leverage.

## Future Improvements

One area of potential enhancement is the introduction of an automated dynamic strike offset based on market conditions. Currently, strike prices are computed based on a fixed basis with manual strike offset available for the vault manager. point offset from spot, but in the future, this could be made adaptive, responding to changing volatility regimes or market skew to optimize returns.

The current implementation is designed with a single collateral asset, such as ETH or stETH. Future versions may support multi-collateral strategies, including assets like BTC or even stablecoins, broadening the appeal of the vault and diversifying its risk exposure.

Lastly, integrating with real-time volatility oracles would allow the vault to dynamically calibrate its implied volatility assumptions. Instead of relying on a static IV parameter, the system could react to market data in real time, improving option pricing accuracy and potentially enhancing yield while maintaining appropriate risk coverage.
