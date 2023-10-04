// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/IUniswapRouter.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import {PoolModifyPositionTest} from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";

contract Treasury {
    address private owner;
    address public buybackHook;
    address private token0;
    address private token1;
    PoolModifyPositionTest modifyPositionRouter;
    PoolSwapTest swapRouter;
    PoolKey poolKey;

    uint160 public constant MIN_PRICE_LIMIT = TickMath.MIN_SQRT_RATIO + 1;
    uint160 public constant MAX_PRICE_LIMIT = TickMath.MAX_SQRT_RATIO - 1;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    constructor(
        address _usdcTokenAddress,
        address _buybackHook,
        PoolKey _poolKey
    ) {
        owner = msg.sender;
        token0 = _usdcTokenAddress;
        buybackHook = _buybackHook;
        poolKey = _poolKey;
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

    function approveHook(address hook, uint amount) external onlyOwner {
        IERC20(token0).approve(hook, amount);
    }

    function transferUSDC(address recipient, uint amount) external onlyHook {
        IERC20(token0).transfer(recipient, amount);
    }

    function receiveTokens(address token, uint amount) external onlyHook {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function deposit(uint256 amount) external {
        IERC20 usdcToken = IERC20(token0);

        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer USDC"
        );
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint256 amount) external onlyOwner {
        IERC20 usdcToken = IERC20(token0);
        require(
            usdcToken.balanceOf(address(this)) >= amount,
            "Insufficient USDC balance"
        );

        require(
            usdcToken.transfer(msg.sender, amount),
            "Failed to transfer USDC"
        );
        emit Withdrawal(msg.sender, amount);
    }

    function swap(PoolKey memory key, int256 amountSpecified, bool zeroForOne, bytes memory hookData) internal {
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
        });

        PoolSwapTest.TestSettings memory settings =
                            PoolSwapTest.TestSettings({withdrawTokens: true, settleUsingTransfer: true});

        swapRouter.swap(key, params, settings, hookData);
    }

}
