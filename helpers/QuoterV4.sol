// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {SafeCast} from "@uniswap/v4-core/contracts/libraries/SafeCast.sol";
import {TickMath} from "@uniswap/v4-core/contracts/libraries/TickMath.sol";
import {TickBitmap} from "@uniswap/v4-core/contracts/libraries/TickBitmap";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";

contract QuoterV4 {
    address poolManager;
    using SafeCast for uint256;
    using PoolIdLibrary for PoolKey;


    PoolId poolId;
    PoolKey poolKey;

    constructor(address _poolManager, address _WETH9) {
        poolManager = _poolManager;
    }

    function getPool(address token0,
                    address token1,
                    uint24 fee,
                    int24 tick,
                    IHooks hook
                    ) private view {
        PoolKey memory key = PoolKey(token0, token1, fee, tick, hook);
        poolKey = key;
        bytes32 _poolId = PoolIdLibrary.toId(key);
        poolId = _poolId;
    }

    function parseRevertReason(bytes memory reason)
    private
    pure
    returns (
        uint256 amount,
        uint160 sqrtPriceX96After,
        int24 tickAfter
    )
    {
        if (reason.length != 96) {
            if (reason.length < 68) revert('Unexpected error');
            assembly {
                reason := add(reason, 0x04)
            }
            revert(abi.decode(reason, (string)));
        }
        return abi.decode(reason, (uint256, uint160, int24));
    }

    function handleRevert(
        bytes memory reason,
        IPoolManager poolManager,
        uint256 gasEstimate
    )
    private
    view
    returns (
        uint256 amount,
        uint160 sqrtPriceX96After,
        uint32 initializedTicksCrossed,
        uint256
    )
    {
        int24 tickBefore;
        int24 tickAfter;
        (, tickBefore, , , , , ) = pool.slot0();
        (amount, sqrtPriceX96After, tickAfter) = parseRevertReason(reason);

        initializedTicksCrossed = pool.countInitializedTicksCrossed(tickBefore, tickAfter);

        return (amount, sqrtPriceX96After, initializedTicksCrossed, gasEstimate);
    }

    function quoteExactInputSingle(IPoolManager.SwapParams memory params, uint256 deadline) public returns (
        uint256 amountOut,
        uint160 sqrtPriceX96After,
        uint32 initializedTicksCrossed,
        uint256 gasEstimate
    ) {

        bool zeroForOne = params.zeroForOne;
        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFees, uint24 hookFees) = poolManager.getSlot0(poolId);

        uint256 gasBefore = gasLeft();

        try swapTokens(poolKey, params, deadline) {
        } catch (bytes memory reason) {
            gasEstimate = gasBefore - gasleft();
            //adding in revert
        }
    }

    function swapTokens(
        PoolKey calldata poolKey,
        IPoolManager.SwapParams calldata swapParams,
        uint256 deadline
    ) public payable {
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