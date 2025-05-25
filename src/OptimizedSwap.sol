// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IWETH.sol";

// Custom Errors for gas optimization
    error PairDoesNotExist();
    error InsufficientETH(uint256 required, uint256 sent);

/**
 * @title OptimizedSwap
 * @notice Optimized contract to swap exact tokens using PancakeSwap pairs directly for reduced gas consumption
 */
contract OptimizedSwap {
    // Immutable addresses
    address public immutable factory;
    address public immutable WETH;

    /**
     * @notice Emitted when tokens are successfully swapped
     * @param sender The initiator of the swap
     * @param token Token address being swapped for
     * @param amountIn Amount of ETH (WETH) used
     * @param amountOut Amount of token received
     */
    event TokensSwapped(address indexed sender, address indexed token, uint amountIn, uint amountOut);

    /**
     * @param _factory PancakeSwap Factory address
     * @param _WETH WETH token address
     */
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    // Correct PancakeSwap fee (998 instead of 997)
    function _getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        unchecked {
            amountIn = (reserveIn * amountOut * 1000) / ((reserveOut - amountOut) * 998) + 1;
        }
    }

    /**
     * @notice Swap ETH for an exact amount of tokens directly via PancakeSwap Pair
     * @param token Token address to receive
     * @param amountOut Exact amount of token desired
     * @param to Recipient of tokens
     */
    function swapETHForExactTokens(
        address token,
        uint amountOut,
        address to
    ) external payable {
        address pair = IPancakeFactory(factory).getPair(WETH, token);
        if (pair == address(0)) revert PairDoesNotExist();

        IPancakePair pancakePair = IPancakePair(pair);

        // Ensure reserves are up-to-date before swap to avoid unexpected revert
        pancakePair.sync();

        (uint112 reserve0, uint112 reserve1,) = pancakePair.getReserves();

        (uint reserveIn, uint reserveOut, uint amount0Out, uint amount1Out) = WETH == pancakePair.token0()
            ? (reserve0, reserve1, uint(0), amountOut)
            : (reserve1, reserve0, uint(0), amountOut);

        uint amountIn = _getAmountIn(amountOut, reserveIn, reserveOut);
        if (msg.value < amountIn) revert InsufficientETH(amountIn, msg.value);

        IWETH(WETH).deposit{value: amountIn}();
        IWETH(WETH).transfer(pair, amountIn);

        pancakePair.swap(amount0Out, amount1Out, to, "");

        emit TokensSwapped(msg.sender, token, amountIn, amountOut);

        unchecked {
            if (msg.value > amountIn) {
                payable(msg.sender).transfer(msg.value - amountIn);
            }
        }
    }

    receive() external payable {}
}