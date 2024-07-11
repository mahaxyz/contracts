// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// ███████╗███████╗██████╗  ██████╗
// ╚══███╔╝██╔════╝██╔══██╗██╔═══██╗
//   ███╔╝ █████╗  ██████╔╝██║   ██║
//  ███╔╝  ██╔══╝  ██╔══██╗██║   ██║
// ███████╗███████╗██║  ██║╚██████╔╝
// ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝
// Website: https://zerolend.xyz
// Discord: https://discord.gg/zerolend
// Twitter: https://twitter.com/zerolendxyz

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
