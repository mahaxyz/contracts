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
  function getPrice() public pure override returns (int256 price) {
    price = 0; // todo
  }
}
