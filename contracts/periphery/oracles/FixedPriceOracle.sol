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

import {DumbAggregatorOracle, IAggregatorV3Interface} from "./DumbAggregatorOracle.sol";

/// @title FixedPriceOracle
/// @author maha.xyz
/// @notice A contract that returns a fixed price
contract FixedPriceOracle is DumbAggregatorOracle {
  int256 private immutable price_;

  constructor(int256 _price, uint8 _decimals) DumbAggregatorOracle(_decimals, "Fixed Price Oracle") {
    price_ = _price;
  }

  function getPrice() public view override returns (int256 price) {
    price = price_;
  }

  function getPriceFor(uint256 amount) public view returns (int256) {
    return (latestAnswer() * int256(amount)) / int256(1 * 10 ** decimals());
  }
}
