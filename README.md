# Automated Buyback Hook
This Uniswap V4 hook enables protocols to implement automated token buybacks from their treasury when price drops below a target threshold in a Uniswap Pool. This has been shipped onto the Mumbai Testnet if you want to test this out. Foundry Tests are in progress
[Treasury Contract](https://mumbai.polygonscan.com/address/0xa9eeb49634836043557d12436745f13d2aa71a2f) | [BuyBackHook](https://mumbai.polygonscan.com/address/0x0422a3aeba3f00e1034f3e113e93781620f778db)


## Overview
The buyback hook uses Axiom to access historical price data for the protocol's token. It sets a target price threshold and monitors the current price. When the price crosses below the threshold, the hook automatically executes a buyback:

Transfers ETH from treasury to provide liquidity
Swaps ETH for tokens via the protocol's Uniswap pool
Sends purchased tokens back to the treasury
This provides decentralized on-chain price support using treasury funds.

## Benefits
- Automated price support during declines and volatility
- Flexible liquidity provision from treasury funds
- Maintains healthy token valuation and demand
- Reduces need for manual buyback execution


User Story:
### Monitoring Price:

- As a protocol, I want to ensure my token's price doesn't fall below a certain threshold.
- The Uniswap Hook is tasked with monitoring the current price of the token in the Uniswap pool within the current block.
- Simultaneously, the Axiom Oracle, utilizing zk-proofs, verifies the price by looking back into previous blocks on-chain to ensure accuracy.

### Triggering Buyback:

- If the price falls below the set threshold, the Uniswap Hook signals the Treasury Contract.

### Executing Buyback:

- Upon receiving the signal, the Treasury Contract transfers ETH to Uniswap to provide liquidity.
- It then executes a swap of ETH for tokens via the protocol's Uniswap pool to buy back tokens.

### Settling Funds:

- The purchased tokens are sent back to the Treasury.
- An optional step could be to burn the bought-back tokens to reduce overall supply, aiming to stabilize or increase the token price.

### Logging and Verification:

- All actions and price data are logged for verification and future analysis.
- The Axiom Oracle can provide historical price data to analyze the effectiveness of the buyback mechanism and adjust the threshold or other parameters as necessary.

Architecture Breakdown:
### Treasury Contract:

- **Primary Functions:** Execute swaps on Uniswap, hold protocol funds, and potentially burn bought-back tokens.
- **Interactions:** Communicates with the Uniswap Hook to receive the buyback trigger and interacts with Uniswap to execute the buyback.

### Uniswap Hook:

- **Primary Functions:** Monitors the current price of the token within the current block and triggers the Treasury Contract for buyback when the price falls below the threshold.
- **Interactions:** Communicates with the Axiom Oracle for price verification and the Treasury Contract for triggering buybacks.

### Axiom Oracle:

- **Primary Functions:** Provides historical price data and supports zk-proofs to verify prices across different blocks.
- **Interactions:** Assists the Uniswap Hook in verifying the current price of the token and provides historical price data for analysis.

This architecture and the order of operations aim to create a decentralized, on-chain mechanism for automated price support, reducing manual intervention and providing a systematic approach to maintaining a healthy token valuation.


