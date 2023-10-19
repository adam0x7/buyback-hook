// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IERC20Minimal} from "lib/v4-periphery/lib/v4-core/contracts/interfaces/external/IERC20Minimal.sol";

contract Treasury {
    using CurrencyLibrary for Currency;

    address private owner;
    address   public buybackHook;
    Currency public usdcToken;
    Currency public protocolToken;
    IPoolManager public poolManager;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    error GenericError(string message);

    constructor(
        address _protocolAddress,
        address _usdcTokenAddress,
        address _buybackHook,
        IPoolManager _poolManager
    ) {
        owner = msg.sender;
        protocolToken = CurrencyLibrary.fromId(uint160(_protocolAddress));
        usdcToken = CurrencyLibrary.fromId(uint160(_usdcTokenAddress));
        buybackHook = _buybackHook;
        poolManager = _poolManager;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    modifier onlyHook() {
        require(msg.sender == buybackHook, "Only buyback hook can access");
        _;
    }


    // Getter function for the owner state variable
    function getOwner() external view returns (address) {
        return owner;
    }

    // Getter function for the buybackHook state variable
    function getBuybackHook() external view returns (address) {
        return buybackHook;
    }

    // Getter function for the usdcToken state variable
    function getUsdcToken() external view returns (Currency) {
        return usdcToken;
    }

    // Getter function for the protocolToken state variable
    function getProtocolToken() external view returns (Currency) {
        return protocolToken;
    }

    function deposit(Currency token, uint256 amount) external {
        IERC20Minimal(Currency.unwrap(token)).transferFrom(
            msg.sender, address(this), uint256(uint128(amount))
        );
    }

    function withdraw(Currency token, uint256 amount) external {
        IERC20Minimal(Currency.unwrap(token)).transferFrom(
            address(this), msg.sender, uint256(uint128(amount))
        );
    }

    function swapTokens(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams,
        uint256 deadline
    ) public payable onlyHook {
        poolManager.lock(abi.encode(poolKey, swapParams, deadline));
    }

    function lockAcquired(uint256, bytes calldata data) external returns (bytes memory) {
        if (msg.sender == address(poolManager)) {
            revert GenericError("test");
        }

        (
            PoolKey memory poolKey,
            IPoolManager.SwapParams memory swapParams,
            uint256 deadline
        ) = abi.decode(data, (PoolKey, IPoolManager.SwapParams, uint256));

        if (block.timestamp > deadline) {
            revert GenericError("deadline passed");
        }

        BalanceDelta delta = poolManager.swap(poolKey, swapParams, data);

        _settleCurrencyBalance(poolKey.currency0, delta.amount0());
        _settleCurrencyBalance(poolKey.currency1, delta.amount1());

        return new bytes(0);
    }

    function _settleCurrencyBalance(
        Currency currency,
        int128 deltaAmount
    ) private {
        if (deltaAmount < 0) {
            poolManager.take(currency, msg.sender, uint128(-deltaAmount));
            return;
        }

        if (currency.isNative()) {
            poolManager.settle{value: uint128(deltaAmount)}(currency);
            return;
        }

        IERC20Minimal(Currency.unwrap(currency)).transferFrom(
            msg.sender,
            address(poolManager),
            uint128(deltaAmount)
        );
        poolManager.settle(currency);
    }

}
