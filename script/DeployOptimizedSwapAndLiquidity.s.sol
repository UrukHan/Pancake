// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {OptimizedSwapAndLiquidity} from "../src/OptimizedSwapAndLiquidity.sol";

contract DeployOptimizedSwapAndLiquidity is Script {
    address constant FACTORY = 0x6725F303b657a9451d8BA641348b6761A6CC7a17;
    address constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    function run() external {
        vm.startBroadcast();
        new OptimizedSwapAndLiquidity(FACTORY, WETH);
        vm.stopBroadcast();
    }
}
