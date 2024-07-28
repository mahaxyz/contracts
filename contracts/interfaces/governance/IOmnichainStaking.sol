// SPDX-License-Identifier: AGPL-3.0-or-later
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

import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

import {IERC20, IMultiTokenRewards} from "../core/IMultiTokenRewards.sol";
import {ILocker} from "./ILocker.sol";

// An omni-chain staking contract that allows users to stake their veNFT
// and get some voting power. Once staked the voting power is available cross-chain.
interface IOmnichainStaking is IMultiTokenRewards, IVotes {
  event LpOracleSet(address indexed oldLpOracle, address indexed newLpOracle);
  event ZeroAggregatorSet(address indexed oldZeroAggregator, address indexed newZeroAggregator);
  event Recovered(address token, uint256 amount);
  event RewardsDurationUpdated(uint256 newDuration);
  event TokenLockerUpdated(address previousLocker, address _tokenLocker);
  event RewardsTokenUpdated(address previousToken, address _zeroToken);
  event PoolVoterUpdated(address previousVoter, address _poolVoter);

  function unstakeToken(uint256 tokenId) external;

  function totalVotes() external view returns (uint256);

  // function balanceOf(address account) external view returns (uint256);

  function getLockedNftDetails(address _user) external view returns (uint256[] memory, ILocker.LockedBalance[] memory);

  function getTokenPower(uint256 amount) external view returns (uint256 power);

  error InvalidUnstaker(address, address);
}
