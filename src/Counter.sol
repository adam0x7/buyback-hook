// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {BaseHook} from "lib/v4-periphery/contracts/BaseHook.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/contracts/types/BalanceDelta.sol";
import {ITreasury} from "./ITreasury.sol";
import {ICounter} from "./ICounter.sol";
import {SwapMath} from "lib/v4-periphery/lib/v4-core/contracts/libraries/SwapMath.sol";


contract Counter is BaseHook, ICounter {
    using PoolIdLibrary for PoolKey;
    address public treasury;


    constructor(IPoolManager _poolManager) BaseHook(_poolManager) {}

    function setTreasury(address _treasury) external {
        treasury = _treasury;
    }

    function getHooksCalls() public pure override returns (Hooks.Calls memory) {
        return Hooks.Calls({
            beforeInitialize: false,
            afterInitialize: false,
            beforeModifyPosition: false,
            afterModifyPosition: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false
        });
    }

    function afterSwap(address, PoolKey calldata key, IPoolManager.SwapParams calldata, BalanceDelta, bytes calldata)
        external
        override
        returns (bytes4) {

        bytes32 poolId = PoolIdLibrary.toId(key);

        (sqrtPriceX96,tick,protocolFees, hookFees) = poolManager.getSlot0(id);

        uint price = calculateSpotPrice(sqrtPriceX96);
        uint targetSqrtPrice = calculateSqrtPriceX96(1);

        if (price < 1) {
            //Ideally, here we would call a quote to attempt to find our target amount that we need to swap
            //As of the time of this hook writing there is no V4 quoter, so we're going to just swap a hardcoded amount
            IPoolManager.SwapParams swapParams = (true, 1000, targetSqrtPrice);
            treasury.swapTokens(key, swapParams , 50);
        }

        return Counter.afterSwap.selector;
    }

    function calculateSpotPrice(uint priceX96) internal pure returns (uint usdcPrice) {
            uint q = 2 ** 96;
            uint p = (priceX96 / q) ** 2;
            //protocol token
            uint decimal0 = 1e18;
            //usdc token
            uint decimal1 = 1e6;
            usdcPrice = p * decimal0 / decimal1;
    }

    function calculateSqrtPriceX96(uint256 price) internal pure returns (uint160) {
        return uint160(sqrt(price) * (1 << 96));
    }

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = x;
        uint256 y = (z + 1) / 2;
        while (y < z) {
            z = y;
            y = (z + x / z) / 2;
        }
        return z;
    }

}
