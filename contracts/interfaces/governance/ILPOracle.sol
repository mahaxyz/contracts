// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ILPOracle {
  /// @notice Gets the price of the liquidity pool token.
  /// @dev This function fetches reserves from the Nile AMM and uses a pre-defined price for tokens to calculate the LP token price.
  /// @return price The price of the liquidity pool token.
  function getPrice() external view returns (uint256 price);

  /// @notice Computes the square root of a given number using the Babylonian method.
  /// @dev This function uses an iterative method to compute the square root of a number.
  /// @param x The number to compute the square root of.
  /// @return y The square root of the given number.
  function sqrt(uint256 x) external pure returns (uint256 y);
}
