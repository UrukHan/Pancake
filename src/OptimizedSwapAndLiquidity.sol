// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./interfaces/IPancakeFactory.sol";
import "./interfaces/IPancakePair.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";

// Custom Errors
    error PairDoesNotExist();
    error InsufficientETH(uint256 required, uint256 sent);
    error WETHTransferFailed();

/**
 * @title OptimizedSwapAndLiquidity
 * @notice Optimized contract for swapping exact tokens and adding liquidity directly to PancakeSwap pairs without using router
 */
contract OptimizedSwapAndLiquidity {
    address public immutable factory;
    address public immutable WETH;

    event TokensSwappedAndLiquidityAdded(
        address indexed sender,
        address indexed token,
        uint amountIn,
        uint amountOut,
        uint liquidityTokens
    );

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    /// @dev Sort tokens to maintain consistent token order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'Identical addresses');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'Zero address');
    }

    /// @dev Calculate required ETH amount for token swap
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        amountIn = (reserveIn * amountOut * 10000) / ((reserveOut - amountOut) * 9975) + 1;
    }

    /// @dev Internal function to handle swap and return token amount
    function _swapExactTokens(address pair, uint amountIn, uint amountOut, address token0) internal {
        IWETH(WETH).deposit{value: amountIn}();
        if (!IWETH(WETH).transfer(pair, amountIn)) revert WETHTransferFailed();

        (uint amount0Out, uint amount1Out) = WETH == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
        IPancakePair(pair).swap(amount0Out, amount1Out, address(this), "");
    }

    /// @dev Internal function to handle liquidity addition
    function _addLiquidity(address pair, address token, uint tokenBalance, uint ethLeft) internal returns (uint liquidity) {
        IWETH(WETH).deposit{value: ethLeft}();

        IERC20(token).transfer(pair, tokenBalance);
        IERC20(WETH).transfer(pair, ethLeft);

        liquidity = IPancakePair(pair).mint(msg.sender);
    }

    /**
     * @notice Swaps ETH for exact tokens and adds liquidity directly to PancakeSwap pair
     * @param token Token address to swap
     * @param amountOut Exact amount of tokens desired
     */
    function swapETHForExactTokensAndAddLiquidity(
        address token,
        uint amountOut
    ) external payable {
        address pair = IPancakeFactory(factory).getPair(WETH, token);
        if (pair == address(0)) revert PairDoesNotExist();

        (uint112 reserve0, uint112 reserve1,) = IPancakePair(pair).getReserves();
        (address token0,) = sortTokens(WETH, token);

        (uint reserveIn, uint reserveOut) = WETH == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        uint amountIn = getAmountIn(amountOut, reserveIn, reserveOut);

        if (msg.value < amountIn) revert InsufficientETH(amountIn, msg.value);

        _swapExactTokens(pair, amountIn, amountOut, token0);

        uint tokenBalance = IERC20(token).balanceOf(address(this));
        uint ethLeft = msg.value - amountIn;

        uint liquidity = _addLiquidity(pair, token, tokenBalance, ethLeft);

        emit TokensSwappedAndLiquidityAdded(msg.sender, token, amountIn, amountOut, liquidity);

        if (address(this).balance > 0) payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {}
}