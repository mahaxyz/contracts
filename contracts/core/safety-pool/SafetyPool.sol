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

import {ISafetyPool} from "../../interfaces/core/ISafetyPool.sol";
import {SafetyPoolEvents} from "../../interfaces/events/SafetyPoolEvents.sol";

import {IERC20, IOmnichainStaking, MultiStakingRewardsERC4626} from "../utils/MultiStakingRewardsERC4626.sol";

/**
 * @title The SafetyPool contract
 * @author maha.xyz
 * @notice Used to pay off any bad debt that may occur in the protocol and also accure rewards
 * @dev https://docs.maha.xyz/mechanics/safety-pool
 */
contract SafetyPool is MultiStakingRewardsERC4626, ISafetyPool {
  /// @inheritdoc ISafetyPool
  bytes32 public immutable MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @inheritdoc ISafetyPool
  function initialize(
    address _stablecoin,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _stakingBoost
  ) external reinitializer(1) {
    __MultiStakingRewardsERC4626_init(
      "Staked ZAI",
      "sZAI",
      _stablecoin,
      86_400 * 10,
      _governance,
      _rewardToken1,
      _rewardToken2,
      _rewardsDuration,
      _stakingBoost
    );
  }

  /// @inheritdoc ISafetyPool
  function coverBadDebt(uint256 amount) external onlyRole(MANAGER_ROLE) {
    IERC20(asset()).transfer(msg.sender, amount);
    emit SafetyPoolEvents.BadDebtCovered(amount, msg.sender);
  }

  function setStakingBoost(address _stakingBoost) external onlyRole(DEFAULT_ADMIN_ROLE) {
    staking = IOmnichainStaking(_stakingBoost);
  }

  /// @dev Override the _calculateBoostedBalance function to account for the withdrawal queue
  function _calculateBoostedBalance(address account)
    internal
    view
    override
    returns (uint256 boostedBalance_, uint256 boostedTotalSupply_)
  {
    if (withdrawalTimestamp[account] > 0) return (0, _boostedTotalSupply);
    (boostedBalance_, boostedTotalSupply_) = super._calculateBoostedBalance(account);
  }
}
