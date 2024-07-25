// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMultiStakingRewardsERC4626 {
  function DISTRIBUTOR_ROLE() external view returns (bytes32);

  /// @notice Time at which distribution ends
  function periodFinish(IERC20 reward) external view returns (uint256);

  /// @notice Reward per second given to the staking contract, split among the staked tokens
  function rewardRate(IERC20 reward) external view returns (uint256);

  /// @notice Duration of the reward distribution
  function rewardsDuration() external view returns (uint256);

  /// @notice Last time `rewardPerTokenStored` was updated
  function lastUpdateTime(IERC20 reward) external view returns (uint256);

  /// @notice Helps to compute the amount earned by someone
  /// Cumulates rewards accumulated for one token since the beginning.
  /// Stored as a uint so it is actually a float times the base of the reward token
  function rewardPerTokenStored(IERC20 reward) external view returns (uint256);

  /// @notice Stores for each account the `rewardPerToken`: we do the difference
  /// between the current and the old value to compute what has been earned by an account
  function userRewardPerTokenPaid(IERC20 reward, address who) external view returns (uint256);

  /// @notice Stores for each account the accumulated rewards
  function rewards(IERC20 reward, address who) external view returns (uint256);

  function rewardToken2() external view returns (IERC20);
  function rewardToken1() external view returns (IERC20);

  /// @notice Queries the last timestamp at which a reward was distributed
  /// @dev Returns the current timestamp if a reward is being distributed and the end of the staking
  /// period if staking is done
  function lastTimeRewardApplicable(IERC20 token) external view returns (uint256);

  /// @notice Used to actualize the `rewardPerTokenStored`
  /// @dev It adds to the reward per token: the time elapsed since the `rewardPerTokenStored` was
  /// last updated multiplied by the `rewardRate` divided by the number of tokens
  function rewardPerToken(IERC20 token) external view returns (uint256);

  /// @notice Returns how much a given account earned rewards
  /// @param account Address for which the request is made
  /// @return How much a given account earned rewards
  /// @dev It adds to the rewards the amount of reward earned since last time that is the difference
  /// in reward per token from now and last time multiplied by the number of tokens staked by the person
  function earned(IERC20 token, address account) external view returns (uint256);

  /// @notice Triggers a payment of the reward earned to the msg.sender
  function getReward(address who, IERC20 token) external;

  /// @notice Adds rewards to be distributed
  /// @param reward Amount of reward tokens to distribute
  /// @dev This reward will be distributed during `rewardsDuration` set previously
  function notifyRewardAmount(IERC20 token, uint256 reward) external;
}
