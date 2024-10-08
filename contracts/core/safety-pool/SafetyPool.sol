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

import {IERC20, MultiStakingRewardsERC4626} from "../utils/MultiStakingRewardsERC4626.sol";

/**
 * @title The SafetyPool contract
 * @author maha.xyz
 * @notice Used to pay off any bad debt that may occur in the protocol
 * @dev https://docs.maha.xyz/mechanics/safety-pool
 */
contract SafetyPool is MultiStakingRewardsERC4626, ISafetyPool {
  /// @inheritdoc ISafetyPool
  bytes32 public immutable MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @inheritdoc ISafetyPool
  uint256 public withdrawalDelay;

  /// @inheritdoc ISafetyPool
  mapping(address => uint256) public withdrawalTimestamp;

  /// @inheritdoc ISafetyPool
  mapping(address => uint256) public withdrawalAmount;

  /// @inheritdoc ISafetyPool
  function initialize(
    string memory _name,
    string memory _symbol,
    address _stablecoin,
    uint256 _withdrawalDelay,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration,
    address _stakingBoost
  ) external reinitializer(1) {
    __MultiStakingRewardsERC4626_init(
      _name, _symbol, _stablecoin, _governance, _rewardToken1, _rewardToken2, _rewardsDuration, _stakingBoost
    );
    withdrawalDelay = _withdrawalDelay;
  }

  /// @inheritdoc ISafetyPool
  function queueWithdrawal(uint256 shares) external {
    require(shares <= balanceOf(msg.sender), "insufficient balance");
    withdrawalTimestamp[msg.sender] = block.timestamp + withdrawalDelay;
    withdrawalAmount[msg.sender] = shares;
    emit SafetyPoolEvents.WithdrawalQueueUpdated(shares, withdrawalTimestamp[msg.sender], msg.sender);

    _updateRewardDual(rewardToken1, rewardToken2, msg.sender);
  }

  /// @inheritdoc ISafetyPool
  function cancelWithdrawal() external {
    withdrawalTimestamp[msg.sender] = 0;
    withdrawalAmount[msg.sender] = 0;
    emit SafetyPoolEvents.WithdrawalQueueUpdated(0, 0, msg.sender);

    _updateRewardDual(rewardToken1, rewardToken2, msg.sender);
  }

  /// @inheritdoc ISafetyPool
  function coverBadDebt(uint256 amount) external onlyRole(MANAGER_ROLE) {
    IERC20(asset()).transfer(msg.sender, amount);
    emit SafetyPoolEvents.BadDebtCovered(amount, msg.sender);
  }

  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    uint256 amount = withdrawalAmount[owner];

    require(withdrawalTimestamp[owner] <= block.timestamp, "withdrawal not ready");
    require(shares == amount && amount > 0, "invalid withdrawal");

    withdrawalTimestamp[owner] = 0;
    withdrawalAmount[owner] = 0;
    emit SafetyPoolEvents.WithdrawalQueueUpdated(0, 0, owner);

    super._withdraw(caller, receiver, owner, assets, shares);
  }

  /// @dev Override the _calculateBoostedBalance function to account for the withdrawal queue
  function _calculateBoostedBalance(address account)
    internal
    view
    override
    returns (uint256 boostedBalance_, uint256 boostedTotalSupply_)
  {
    if (withdrawalTimestamp[account] > 0) {
      return (0, _boostedTotalSupply);
    }

    (boostedBalance_, boostedTotalSupply_) = super._calculateBoostedBalance(account);
  }
}
