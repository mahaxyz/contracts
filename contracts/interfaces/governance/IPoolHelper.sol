// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPoolHelper {
    function lpTokenAddr() external view returns (address);

    function zapWETH(uint256 amount) external returns (uint256);

    function zapTokens(
        uint256 _wethAmt,
        uint256 _zeroAmt
    ) external returns (uint256);

    function quoteFromToken(
        uint256 tokenAmount
    ) external view returns (uint256 optimalWETHAmount);

    function quoteWETH(
        uint256 lpAmount
    ) external view returns (uint256 wethAmount);

    function getLpPrice(
        uint256 rdntPriceInEth
    ) external view returns (uint256 priceInEth);

    function getReserves()
        external
        view
        returns (uint256 rdnt, uint256 weth, uint256 lpTokenSupply);

    function getPrice() external view returns (uint256 priceInEth);

    function quoteSwap(
        address _inToken,
        uint256 _wethAmount
    ) external view returns (uint256 tokenAmount);

    function swapToWeth(
        address _inToken,
        uint256 _amount,
        uint256 _minAmountOut
    ) external;
}
