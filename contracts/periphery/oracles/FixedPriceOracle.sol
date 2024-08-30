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

/// @title FixedPriceOracle
/// @author maha.xyz
/// @notice A contract that returns a fixed price
contract FixedPriceOracle is IAggregatorV3Interface {
  uint8 public immutable decimals;
  int256 public immutable price;

  constructor(int256 _price, uint8 _decimals) {
    decimals = _decimals;
    price = _price;
  }

  function description() external pure override returns (string memory) {
    return "";
  }

  function getAnswer(uint256) external view override returns (int256) {
    return price;
  }

  function getTimestamp(uint256) external view override returns (uint256) {
    return block.timestamp;
  }

  function latestAnswer() external view override returns (int256) {
    return price;
  }

  function latestTimestamp() external view override returns (uint256) {
    return block.timestamp;
  }

  function version() external pure override returns (uint256) {
    return 1;
  }
}
