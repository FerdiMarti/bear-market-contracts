`LSPAllocator` is a smart contract module that plugs into the Liquid Stability Pool (LSP) of the BeraBorrow CDP system to generate additional yield for $NECT depositors by writing cash-settled SPX options using idle liquidity. This allocator ensures that the LSP can still execute `offset()` without disruption, while premiums from options flow back to LSP depositors or compound to write more contracts.

## How the Module Safely Leverages LSP Liquidity

- Capital buffer: Only up to `30%` of the LSP’s allocated funds are used to mint options. The rest remains liquid and accessible for `offset()`, maintaining solvency and execution ability for both protocols.
- Short-dated options: Contracts are written with tight expiry windows to reduce exposure to long-term volatility.
- Auto-compounding: Premiums are routed back into the system to write more options or can be withdrawn to the LSP.

## Why It’s Beneficial to Both Protocols and LSP Depositors

This module delivers meaningful benefits to LSP depositors, the BeraBorrow protocol, on-chain traders, and the newly introduced BeraOptions protocol.

For LSP depositors, it unlocks a new yield stream: premiums from options buyers. These premiums are fully retained by the allocator and can either be routed back to the LSP or reinvested to write additional options through auto-compounding. This transforms idle $NECT into an actively utilized asset while preserving enough liquidity to honor `offset()` calls.

For the BeraBorrow protocol, the module increases capital efficiency without sacrificing system solvency. By reserving a configurable buffer and implementing a fallback mechanism that swaps incoming CDP collateral for $NECT when needed, the protocol can continue liquidations without delay even while the allocator is actively writing options.

For on-chain traders, it introduces a new, collateralized and cash-settled options market. They can speculate or hedge using equity options directly on Berachain, without needing to rely on centralized platforms. All settlements are cash-based and trust-minimized, using the Pyth oracle for price resolution.

For the Bear Market protocol, this module creates a sustainable underwriting mechanism. It gains capital to write options without bootstrapping its own liquidity layer, and can grow in tandem with the LSP. Because the allocator owns the option contracts it deploys, it also maintains control over premium flow and systemic risk, allowing the Bear Market protocol to scale in a capital-efficient and modular way.

## Practical Example: $TSLA Cash-Settled Equity Options on Pyth

Our implementation uses a mock integration with $TSLA price feeds via Pyth Network. The deployed options are:

- Collateralized in $NECT.
- Cash-settled in $NECT based on TSLA/USD at expiry.
- Settled automatically or on-demand via a public executeOption() function.

For future development the contract could enable different strategies such as straddles and collars based on market volatility inputs.

## Technical Architecture

- `LSPAllocator.sol`: Allocates LSP funds, writes options, tracks open positions.

- `Option.sol`: Minimal option contract template with constructor-based configuration.

- Auto-compounding and premium tracking are fully modular and programmable.

- Ownership of all options resides with the allocator contract to guarantee flow of premiums.

See below diagram for full architecture:

## Economic Soundness

The design of the allocator module is built around capital preservation, predictable risk, and value alignment across stakeholders. At its core, this strategy turns idle liquidity in the LSP into an income-generating asset without compromising its primary function: backstopping liquidations in the BeraBorrow CDP system.

First, the module enforces a configurable capital buffer, ensuring that a meaningful portion of $NECT remains readily available for emergency `offset()` calls. This means that no matter how active the options issuance becomes, the LSP can always fulfill its role in stabilizing borrower positions during market downturns.

Second, the module issues fully collateralized, short-dated and cash-settled options, which are inherently lower risk and more predictable than long-dated or physically settled contracts. This minimizes directional exposure and reduces the chance of large, unpredictable drawdowns. Additionally, the module supports execution windows to further constrain risk and offer flexibility in settlement timing.

Third, the premiums collected from option buyers are fully retained by the allocator and attributed to LSP capital either through direct return or reinvestment via an auto-compounding mechanism. This allows the protocol to gradually build an organic yield layer for depositors, without needing to dilute $NECT or inflate emissions.

Overall, this architecture allows the Bera ecosystem to gain exposure to options-based yield strategies in a controlled, modular, and capital-efficient way — one that aligns incentives and mitigates systemic fragility.

**Integration with `offset()`**

The **LSPAllocator module** is designed to safely leverage idle NECT liquidity from the Liquid Stability Pool (LSP) without compromising its core function: executing `offset()` during collateral liquidations.

### **How the Module Ensures Compatibility**

To ensure full compatibility with this mechanism, the LSPAllocator enforces two layers of protection:

1. **Liquidity Buffer**  
   A configurable percentage (default: 30%) of the $NECT allocation is always reserved and cannot be used to mint options. This guarantees that a portion of the LSP’s liquidity remains untouched and ready for `offset()` at all times.

2. **Active Reclaim Hook**  
   The contract exposes a public function `reclaimLiquidity(uint256 amount)`, callable only by the LSP, which allows it to reclaim unused $NECT from the allocator in real-time. This provides the protocol with a direct control mechanism to reabsorb liquidity in the lead-up to or during an `offset()` execution.

### **Design Goals Achieved**

- **No interference** with core liquidation logic
- **Additional yield** for LSP depositors via options premiums
- **Composable and modular**, requiring no changes to `offset()` itself
- **Failsafe reclaimability** via explicit `reclaimLiquidity()` entry point

### **Practical Example**

If $300,000 NECT is allocated:

- Only $210,000 is used to write options (70%)

- $90,000 is always kept in reserve (30%)

- If BeraBorrow calls `offset()`, it can immediately call `reclaimLiquidity()` to withdraw unutilized NECT.
