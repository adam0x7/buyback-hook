// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/contracts/types/Currency.sol";

interface ITreasury {
    event Deposit(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);

    function deposit(Currency token, uint256 amount) external;
    function withdraw(Currency token, uint256 amount) external;
    function swapTokens(
        IPoolManager.SwapParams calldata swapParams,
        uint256 deadline
    ) external payable;

    // Getter functions for public state variables
    function getOwner() external view returns (address);
    function getBuybackHook() external view returns (address);
    function getUsdcToken() external view returns (Currency);
    function getProtocolToken() external view returns (Currency);
}
