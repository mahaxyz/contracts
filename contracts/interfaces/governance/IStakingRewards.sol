// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards {
  function notifyRewardAmount(uint256 reward) external;

  function recoverERC20(address tokenAddress, address to, uint256 tokenAmount) external;

  function rewardToken() external view returns (IERC20);

  function setNewRewardsDistribution(address newRewardsDistribution) external;

  event RewardAdded(uint256 reward);

  event Staked(address indexed user, uint256 amount);

  event Withdrawn(address indexed user, uint256 amount);

  event RewardPaid(address indexed user, uint256 reward);

  event Recovered(address indexed tokenAddress, address indexed to, uint256 amount);

  event RewardsDistributionUpdated(address indexed _rewardsDistribution);
}
