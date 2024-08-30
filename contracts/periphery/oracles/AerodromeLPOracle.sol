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

import {IAggregatorV3Interface} from "../../interfaces/governance/IAggregatorV3Interface.sol";
import {IUniswapV2Pair} from "../../interfaces/periphery/uniswap/IUniswapV2Pair.sol";

/// @title AerodromeLPOracle
/// @author maha.xyz
/// @notice A contract that returns a price of an LP token on Aerdrome.
/// @dev Reference from
/// https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/master/contracts/oracle/UniswapV2Oracle.sol
contract AerodromeLPOracle is IAggregatorV3Interface {
  uint8 public immutable decimals;

  IUniswapV2Pair public immutable pool;
  IAggregatorV3Interface public immutable tokenAPriceFeed;
  IAggregatorV3Interface public immutable tokenBPriceFeed;

  constructor(uint8 _decimals, address _tokenAPriceFeed, address _tokenBPriceFeed) {
    tokenAPriceFeed = IAggregatorV3Interface(_tokenAPriceFeed);
    tokenBPriceFeed = IAggregatorV3Interface(_tokenBPriceFeed);
    decimals = _decimals;
  }

  function description() public pure override returns (string memory) {
    return "";
  }

  function getAnswer(uint256) public view override returns (int256) {
    return latestAnswer();
  }

  function getTimestamp(uint256) public view override returns (uint256) {
    return block.timestamp;
  }

  function latestAnswer() public view override returns (int256) {
    return int256(getPrice());
  }

  function getPriceFor(uint256 amount) public view returns (int256) {
    return latestAnswer() * int256(amount) / 1e8;
  }

  /// @notice Gets the price of the liquidity pool token.
  /// @dev This function fetches reserves from the Nile AMM and uses a pre-defined price for tokens to calculate the LP
  /// token price.
  /// @return price The price of the liquidity pool token.
  function getPrice() public view returns (uint256 price) {
    (uint256 reserve0, uint256 reserve1,) = pool.getReserves();

    int256 px0 = tokenAPriceFeed.latestAnswer();
    int256 px1 = tokenBPriceFeed.latestAnswer();

    require(px0 > 0 && px1 > 0, "Invalid Price");

    uint256 sqrtK = (sqrt(reserve0 * reserve1) * 1e18) / pool.totalSupply();
    price = (sqrtK * 2 * sqrt(uint256(px0 * px1))) / 1e18;
  }

  /// @notice Computes the square root of a given number using the Babylonian method.
  /// @dev This function uses an iterative method to compute the square root of a number.
  /// @param x The number to compute the square root of.
  /// @return y The square root of the given number.
  function sqrt(uint256 x) internal pure returns (uint256 y) {
    if (x == 0) return 0; // Handle the edge case for 0
    uint256 z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function latestTimestamp() public view override returns (uint256) {
    return block.timestamp;
  }

  function version() public pure override returns (uint256) {
    return 1;
  }
}
