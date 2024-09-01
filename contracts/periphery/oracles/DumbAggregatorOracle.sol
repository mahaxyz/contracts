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

abstract contract DumbAggregatorOracle is IAggregatorV3Interface {
  uint8 internal decimals_ = 18;
  string internal description_;

  constructor(uint8 _decimals, string memory _description) {
    decimals_ = _decimals;
    description_ = _description;
  }

  function getAnswer(uint256) public view override returns (int256) {
    return latestAnswer();
  }

  function decimals() public view returns (uint8) {
    return decimals_;
  }

  function description() public view override returns (string memory) {
    return description_;
  }

  function getTimestamp(uint256) public view override returns (uint256) {
    return block.timestamp;
  }

  function latestAnswer() public view override returns (int256) {
    return int256(getPrice());
  }

  function getPrice() public view virtual returns (int256 price);

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
