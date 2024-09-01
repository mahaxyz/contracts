// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.21;

import {IAerodromePool} from "../../interfaces/periphery/dex/IAerodromePool.sol";
import {DumbAggregatorOracle, IAggregatorV3Interface} from "./DumbAggregatorOracle.sol";

/// @title AerodromeLPOracle
/// @author maha.xyz
/// @notice A contract that returns a price of an LP token on Aerdrome.
/// @dev Reference from
/// https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/master/contracts/oracle/UniswapV2Oracle.sol
contract AerodromeLPOracle is DumbAggregatorOracle {
  IAerodromePool public immutable pool;
  IAggregatorV3Interface public immutable tokenAPriceFeed;
  IAggregatorV3Interface public immutable tokenBPriceFeed;

  bool public immutable stable;
  uint256 public immutable decimals0;
  uint256 public immutable decimals1;

  constructor(
    address _tokenAPriceFeed,
    address _tokenBPriceFeed,
    address _pool
  ) DumbAggregatorOracle(18, "Aerodrome LP Oracle") {
    tokenAPriceFeed = IAggregatorV3Interface(_tokenAPriceFeed);
    tokenBPriceFeed = IAggregatorV3Interface(_tokenBPriceFeed);
    pool = IAerodromePool(_pool);
    stable = pool.stable();

    (uint256 dec0, uint256 dec1,,,,,) = pool.metadata();
    decimals0 = dec0;
    decimals1 = dec1;
  }

  function getPriceFor(uint256 amount) public view returns (int256) {
    return (latestAnswer() * int256(amount)) / 1e18;
  }

  /// @notice Gets the price of the liquidity pool token.
  /// @dev This function fetches reserves from the Nile AMM and uses a pre-defined price for tokens to calculate the LP
  /// token price.
  /// @return price The price of the liquidity pool token.
  function getPrice() public view override returns (int256 price) {
    uint256 k = getK();
    uint256 px0 = uint256(tokenAPriceFeed.latestAnswer());
    uint256 px1 = uint256(tokenBPriceFeed.latestAnswer());

    require(px0 > 0 && px1 > 0, "Invalid Price");

    uint256 sqrtK = (sqrt(k) * 1e18) / pool.totalSupply();
    price = int256(sqrtK * 2 * sqrt(px0 * px1) / 1e18);
  }

  /// @notice Computes the square root of a given number using the Babylonian method.
  /// @dev This function uses an iterative method to compute the square root of a number.
  /// @param x The number to compute the square root of.
  /// @return y The square root of the given number.
  function sqrt(uint256 x) public pure returns (uint256 y) {
    if (x == 0) return 0; // Handle the edge case for 0
    uint256 z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function _k(uint256 x, uint256 y, uint256 _decimals0, uint256 _decimals1) internal view returns (uint256) {
    if (stable) {
      uint256 _x = (x * 1e18) / _decimals0;
      uint256 _y = (y * 1e18) / _decimals1;
      uint256 _a = (_x * _y) / 1e18;
      uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      return (_a * _b) / 1e18; // x3y+y3x >= k
    } else {
      return x * y; // xy >= k
    }
  }

  function getK() public view returns (uint256) {
    (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
    return _k(reserve0, reserve1, decimals0, decimals1);
  }
}
