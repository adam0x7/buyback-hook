# Automated Buyback Hook
This Uniswap V4 hook enables protocols to implement automated token buybacks from their treasury when price drops below a target threshold in a Uniswap Pool. This has been shipped onto the Mumbai Testnet if you want to test this out. Foundry Tests are in progress
[Treasury Contract](https://mumbai.polygonscan.com/address/0xa9eeb49634836043557d12436745f13d2aa71a2f) | [BuyBackHook](https://mumbai.polygonscan.com/address/0x0422a3aeba3f00e1034f3e113e93781620f778db)


## Overview
The buyback hook sets a target price threshold and monitors the current price after every swap. When the price crosses below the threshold, the hook automatically executes a buyback:

Transfers ETH from treasury to provide liquidity
Swaps ETH for tokens via the protocol's Uniswap pool
Sends purchased tokens back to the treasury
This provides decentralized on-chain price support using treasury funds.

## Benefits
- Automated price support during declines and volatility
- Flexible liquidity provision from treasury funds
- Maintains healthy token valuation and demand
- Reduces need for manual buyback execution


# Architecture Breakdown:
### Treasury Contract:

- **Primary Functions:** Execute swaps on Uniswap, hold protocol funds, and potentially burn bought-back tokens.
- **Interactions:** Communicates with the Uniswap Hook to receive the buyback trigger and interacts with Uniswap to execute the buyback.

### Uniswap Hook:

- **Primary Functions:** Monitors the current price of the token within the current block and triggers the Treasury Contract for buyback when the price falls below the threshold.
- **Interactions:** Communicates with the Axiom Oracle for price verification and the Treasury Contract for triggering buybacks.

This architecture and the order of operations aim to create a decentralized, on-chain mechanism for automated price support, reducing manual intervention and providing a systematic approach to maintaining a healthy token valuation.


