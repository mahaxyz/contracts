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

  // https://github.com/aerodrome-finance/contracts/blob/main/contracts/Pool.sol#L401-L405
  // _f(x, y) = xy (x^2 + y^2)
  function _f(uint256 x0, uint256 y) internal pure returns (uint256) {
    uint256 _a = (x0 * y) / 1e18;
    uint256 _b = ((x0 * x0) / 1e18 + (y * y) / 1e18);
    return (_a * _b) / 1e18;
  }

  // https://github.com/aerodrome-finance/contracts/blob/main/contracts/Pool.sol#L407-L409
  // _d(x, y) = 3x(y^2) + x^3
  function _d(uint256 x0, uint256 y) internal pure returns (uint256) {
    return (3 * x0 * ((y * y) / 1e18)) / 1e18 + ((((x0 * x0) / 1e18) * x0) / 1e18);
  }

  // https://github.com/aerodrome-finance/contracts/blob/main/contracts/Pool.sol#L411-L451
  function _get_y(uint256 x0, uint256 xy, uint256 y) internal view returns (uint256) {
    for (uint256 i = 0; i < 255; i++) {
      uint256 k = _f(x0, y);
      if (k < xy) {
        // there are two cases where dy == 0
        // case 1: The y is converged and we find the correct answer
        // case 2: _d(x0, y) is too large compare to (xy - k) and the rounding error
        //         screwed us.
        //         In this case, we need to increase y by 1
        uint256 dy = ((xy - k) * 1e18) / _d(x0, y);
        if (dy == 0) {
          if (k == xy) {
            // We found the correct answer. Return y
            return y;
          }
          if (_k(x0, y + 1) > xy) {
            // If _k(x0, y + 1) > xy, then we are close to the correct answer.
            // There's no closer answer than y + 1
            return y + 1;
          }
          dy = 1;
        }
        y = y + dy;
      } else {
        uint256 dy = ((k - xy) * 1e18) / _d(x0, y);
        if (dy == 0) {
          if (k == xy || _f(x0, y - 1) < xy) {
            // Likewise, if k == xy, we found the correct answer.
            // If _f(x0, y - 1) < xy, then we are close to the correct answer.
            // There's no closer answer than "y"
            // It's worth mentioning that we need to find y where f(x0, y) >= xy
            // As a result, we can't return y - 1 even it's closer to the correct answer
            return y;
          }
          dy = 1;
        }
        y = y - dy;
      }
    }
    revert("!y");
  }

  function _k(uint256 x, uint256 y) internal view returns (uint256) {
    if (stable) {
      uint256 _x = (x * 1e18) / decimals0;
      uint256 _y = (y * 1e18) / decimals1;
      uint256 _a = (_x * _y) / 1e18;
      uint256 _b = ((_x * _x) / 1e18 + (_y * _y) / 1e18);
      return (_a * _b) / 1e18; // x3y+y3x >= k
    } else {
      return x * y; // xy >= k
    }
  }

  function getK() public view returns (uint256) {
    (uint256 reserve0, uint256 reserve1,) = pool.getReserves();
    return _k(reserve0, reserve1);
  }

  function getY(uint256 x0, uint256 xy, uint256 y) public view returns (uint256) {
    return _get_y(x0, xy, y);
  }
}
