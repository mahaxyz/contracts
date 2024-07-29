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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IOmnichainStaking} from "../governance/IOmnichainStaking.sol";
import {IMultiTokenRewards} from "./IMultiTokenRewards.sol";

/**
 * @title IMultiStakingRewardsERC4626
 * @author maha.xyz
 * @notice This interface is used to interact with the MultiStakingRewardsERC4626 contract
 */
interface IMultiStakingRewardsERC4626 is IMultiTokenRewards {
  event UpdatedBoost(address indexed account, uint256 boostedBalance, uint256 boostedTotalSupply);

  /**
   * @notice Gets the role that is able to distribute rewards
   */
  function DISTRIBUTOR_ROLE() external view returns (bytes32);

  /**
   * @notice Gets the total supply of boosted tokens
   */
  function totalBoostedSupply() external view returns (uint256);

  /**
   * @notice Gets the total voting power of all the participants
   */
  function totalVotingPower() external view returns (uint256);

  /**
   * @notice Gets the boosted balance for an account
   * @dev Code taken from
   * https://github.com/curvefi/curve-dao-contracts/blob/master/contracts/gauges/LiquidityGaugeV5.vy#L191-L213
   */
  function boostedBalance(address who) external view returns (uint256);

  /**
   * @notice Gets the voting power for an account
   * @param who The account for which the voting power is requested
   */
  function votingPower(address who) external view returns (uint256);

  /**
   * @notice Gets the staking contract that returns the voting power of an account
   */
  function staking() external view returns (IOmnichainStaking);

  /**
   * @notice Grants approval to the staking contract to spend the underlying token using permits
   */
  function approveUnderlyingWithPermit(uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}
