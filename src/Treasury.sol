// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Interfaces/IERC20.sol";
import "./Interfaces/IUniswapRouter.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/contracts/types/PoolId.sol";

contract Treasury {
    address private owner;
    address public buybackHook;
    address private token0;
    address private token1;

    event Deposit(address indexed from, uint256 amount);

    event Withdrawal(address indexed to, uint256 amount);

    constructor(
        address _usdcTokenAddress,
        address _buybackHook
    ) {
        owner = msg.sender;
        token0 = _usdcTokenAddress;
        buybackHook = _buybackHook;
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

    // Deposit funds into the treasury contract
    function deposit(uint256 amount) external {
        IERC20 usdcToken = IERC20(token0);

        require(
            usdcToken.transferFrom(msg.sender, address(this), amount),
            "Failed to transfer USDC"
        );
        emit Deposit(msg.sender, amount);
    }

    // Withdraw funds from the treasury contract
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

    function swapTokens() external onlyOwner {
        IPoolManager.SwapParams swapParams = IPoolManager.SwapParams(false, 100, 0);
        poolKey = PoolKey(Currency.wrap(address(token0)), Currency.wrap(address(token1)), 3000, 60, IHooks(counter));
        bytes memory hookData = abi.encode(buybackHook);
        buybackHook.poolManager.swap(poolKey, swapParams,hookData);
    }

}
