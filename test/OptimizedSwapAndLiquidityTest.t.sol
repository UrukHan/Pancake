// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import {IPancakeFactory} from "../src/interfaces/IPancakeFactory.sol";
import {IPancakePair} from "../src/interfaces/IPancakePair.sol";
import {PancakeLibrary} from "../src/libraries/PancakeLibrary.sol";
import {Test} from "forge-std/Test.sol";
import {OptimizedSwapAndLiquidity, PairDoesNotExist, InsufficientETH} from "../src/OptimizedSwapAndLiquidity.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract OptimizedSwapAndLiquidityTest is Test {
    OptimizedSwapAndLiquidity s_swap;

    address constant WETH = address(0xae13d989dac2f0debff460ac112a837c89baa7cd);
    address constant FACTORY = address(0x6725F303b657a9451d8BA641348b6761A6CC7a17);
    address constant TOKEN = address(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);

    address s_user = 0x164E57ba98c44777E2e76f98E007521409C6d491;

    event TokensSwappedAndLiquidityAdded(address indexed sender, address indexed token, uint amountIn, uint amountOut, uint liquidityTokens);

    function setUp() external {
        s_swap = new OptimizedSwapAndLiquidity(FACTORY, WETH);
        vm.deal(s_user, 100 ether);
    }

    function testSwapETHForExactTokensAndLiquidity() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = TOKEN;

        uint amountOut = 1 ether;
        uint[] memory amounts = PancakeLibrary.getAmountsIn(FACTORY, amountOut, path);
        uint amountIn = amounts[0];

        uint256 ethSent = amountIn + 0.01 ether;

        uint256 lpBalanceBefore = IERC20(IPancakeFactory(FACTORY).getPair(WETH, TOKEN)).balanceOf(s_user);

        vm.expectEmit(true, true, false, true);
        emit TokensSwappedAndLiquidityAdded(s_user, TOKEN, amountIn, amountOut, 0); // Liquidity approximate, using 0 for simplicity

        s_swap.swapETHForExactTokensAndAddLiquidity{value: ethSent}(TOKEN, amountOut);

        uint256 lpBalanceAfter = IERC20(IPancakeFactory(FACTORY).getPair(WETH, TOKEN)).balanceOf(s_user);

        console.log("LP tokens received:", lpBalanceAfter - lpBalanceBefore);
        assertGt(lpBalanceAfter, lpBalanceBefore, "Liquidity tokens not received");

        vm.stopPrank();
    }

    function testRevertInsufficientETH() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        uint256 amountOut = 0.01 ether;
        uint256 insufficientEth = 1 wei;

        vm.expectRevert(abi.encodeWithSelector(InsufficientETH.selector, 0, insufficientEth));
        s_swap.swapETHForExactTokensAndAddLiquidity{value: insufficientEth}(TOKEN, amountOut);

        vm.stopPrank();
    }

    function testRevertPairDoesNotExist() external {
        vm.createSelectFork("bsc");
        vm.startPrank(s_user);

        address nonexistentToken = address(0x0000000000000000000000000000000000000001);
        uint256 amountOut = 0.01 ether;

        vm.expectRevert(abi.encodeWithSelector(PairDoesNotExist.selector));
        s_swap.swapETHForExactTokensAndAddLiquidity{value: 1 ether}(nonexistentToken, amountOut);

        vm.stopPrank();
    }
}