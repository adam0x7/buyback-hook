# Automated Buyback Hook
This Uniswap V4 hook enables protocols to implement automated token buybacks from their treasury when price drops below a target threshold in a Uniswap Pool.

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

