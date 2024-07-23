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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockAggregator is Ownable {
  int256 public latestAnswer;

  constructor(int256 _answer) Ownable(msg.sender) {
    latestAnswer = _answer;
  }

  function setAnswer(int256 _answer) external onlyOwner {
    latestAnswer = _answer;
  }

  function decimals() external pure returns (uint8) {
    return 8;
  }
}
