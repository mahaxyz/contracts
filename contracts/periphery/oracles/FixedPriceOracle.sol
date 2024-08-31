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

  function description() public pure override returns (string memory) {
    return "An oracle with a fixed price";
  }

  function getAnswer(uint256) public view override returns (int256) {
    return price;
  }

  function getTimestamp(uint256) public view override returns (uint256) {
    return block.timestamp;
  }

  function latestAnswer() public view override returns (int256) {
    return price;
  }

  function latestTimestamp() public view override returns (uint256) {
    return block.timestamp;
  }

  function version() public pure override returns (uint256) {
    return 1;
  }

  function getRoundData(uint80)
    public
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return (0, latestAnswer(), block.timestamp, block.timestamp, 0);
  }

  function latestRoundData()
    public
    view
    override
    returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
  {
    return getRoundData(0);
  }
}
