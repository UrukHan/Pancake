// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";
import {IPancakePair} from "../src/interfaces/IPancakePair.sol";
import {Test} from "forge-std/Test.sol";
import {OptimizedSwap, PairDoesNotExist} from "../src/OptimizedSwap.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract OptimizedSwapTest is Test {
    OptimizedSwap s_swap;

    address constant WETH = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant FACTORY = address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73);
    address constant TOKEN = address(0x55d398326f99059fF775485246999027B3197955);

    address s_user;

    function setUp() external {
        s_user = vm.addr(1);
        s_swap = new OptimizedSwap(FACTORY, WETH);
        vm.deal(s_user, 100 ether);
    }

    function testSwapETHForExactTokens() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        address pair = IPancakeFactory(FACTORY).getPair(WETH, TOKEN);
        IPancakePair pancakePair = IPancakePair(pair);

        (uint112 reserve0, uint112 reserve1,) = pancakePair.getReserves();
        address token0 = pancakePair.token0();
        (uint reserveIn, uint reserveOut) = WETH == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

        uint256 amountOut = 10 * 10**18;
        uint256 amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 998) + 1;

        uint256 ethSent = amountIn + 0.01 ether; // запас

        uint256 balanceBefore = IERC20(TOKEN).balanceOf(s_user);

        s_swap.swapETHForExactTokens{value: ethSent}(TOKEN, amountOut, s_user);

        uint256 balanceAfter = IERC20(TOKEN).balanceOf(s_user);

        assertEq(balanceAfter - balanceBefore, amountOut, "Incorrect token amount received");

        vm.stopPrank();
    }

    function testRevertInsufficientETH() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        uint256 amountOut = 0.01 ether;
        uint256 insufficientEth = 1 wei;

        vm.expectRevert();
        s_swap.swapETHForExactTokens{value: insufficientEth}(TOKEN, amountOut, s_user);

        vm.stopPrank();
    }

    function testRevertPairDoesNotExist() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        address nonexistentToken = address(0x0000000000000000000000000000000000000001);
        uint256 amountOut = 0.01 ether;

        vm.expectRevert();
        s_swap.swapETHForExactTokens{value: 1 ether}(nonexistentToken, amountOut, s_user);

        vm.stopPrank();
    }
}