// SPDX-License-Identifier: UNLICENSED
//Forked some of the logic from https://github.com/saucepoint/v4-axiom-rebalancing/blob/main/script/2_PoolInit.s.sol
// Follow @saucepoint on Github for great Uniswap hooks code examples
pragma solidity ^0.8.19;

import {Script, console2} from "forge-std/Script.sol";
import { Treasury } from "../src/Treasury.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {Counter} from "../src/Counter.sol";
import {Hooks} from "@uniswap/v4-core/contracts/libraries/Hooks.sol";
import {HookMiner} from "../test/utils/HookMiner.sol";
import {PoolSwapTest} from "@uniswap/v4-core/contracts/test/PoolSwapTest.sol";
import {Deployers} from "@uniswap/v4-core/test/foundry-tests/utils/Deployers.sol";
import { PoolModifyPositionTest } from "@uniswap/v4-core/contracts/test/PoolModifyPositionTest.sol";
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/contracts/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {ICounter} from "../src/ICounter.sol";
import {IHooks} from "@uniswap/v4-core/contracts/interfaces/IHooks.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";

contract TreasuryScript is Script, Deployers {
    address constant CREATE2_DEPLOYER = address(0x13b0D85CcB8bf860b6b79AF3029fCA081AE9beF2); // Mumbai Deployer from -> https://github.com/pcaversaccio/create2deployer
    IPoolManager manager = IPoolManager(0x5FF8780e4D20e75B8599A9C4528D8ac9682e5c89); //Pool Manager address on Mumbai 🦄
    using CurrencyLibrary for Currency;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // deploying our router
        PoolModifyPositionTest router =
        new PoolModifyPositionTest(IPoolManager(address(0x5FF8780e4D20e75B8599A9C4528D8ac9682e5c89)));

        // deploying some mock tokens
        MockERC20 _tokenA = MockERC20(0x9999f7Fea5938fD3b1E26A12c3f2fb024e194f97);
        MockERC20 _tokenB = MockERC20(0x4f81Ff288518727Ae2583f67fEDb46533c9F1238);
        MockERC20 token0;
        MockERC20 token1;


        //token1 can't be longer than token0, we need to make sure that token0 is smaller
        if (address(_tokenA) < address(_tokenB)) {
            token0 = _tokenA;
            token1 = _tokenB;
        } else {
            token0 = _tokenB;
            token1 = _tokenA;
        }

        // mint tokens to sender
        token0.mint(msg.sender, 1000e18);
        token1.mint(msg.sender, 1000e18);

        token0.approve(address(router), 1000e18);
        token1.approve(address(router), 1000e18);


        //setting the flag for the hook that we will be using
        uint160 flags = uint160(Hooks.AFTER_SWAP_FLAG);

        // Mine a salt that will produce a hook address with the correct flags
        (address hookAddress, bytes32 salt) =
                            HookMiner.find(CREATE2_DEPLOYER, flags, 3000, type(Counter).creationCode,
                            abi.encode(address(manager)));


        // Deploying the hook using a CREATE2 address that I found on Mumbai, probably will deploy another soon
        vm.broadcast();
        Counter counter = new Counter{salt: salt}(manager);
        require(address(counter) == hookAddress, "CounterScript: hook address mismatch");

        // init your pool
        PoolKey memory key =
                        PoolKey(Currency.wrap(address(token0)),
                        Currency.wrap(address(token1)),
                        3000, 60, IHooks(counter));

        vm.broadcast();
        manager.initialize(key, SQRT_RATIO_1_1, ZERO_BYTES);

        vm.broadcast();
        Treasury treasury = new Treasury(address(token0), address(token1), manager);
        ICounter(counter).setTreasury(address(treasury));


        vm.broadcast();
        //Setting liquidity at the end here
        router.modifyPosition(key, IPoolManager.ModifyPositionParams(-6000, 6000, 500 ether), abi.encode(msg.sender));
    }

}