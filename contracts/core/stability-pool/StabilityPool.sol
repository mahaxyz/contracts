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

import {AccessControlEnumerableUpgradeable} from
  "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

import {IStabilityPool} from "../../interfaces/core/IStabilityPool.sol";
import {StabilityPoolEvents} from "../../interfaces/events/StabilityPoolEvents.sol";

import {IERC20, MultiStakingRewardsERC4626} from "./MultiStakingRewardsERC4626.sol";

contract StabilityPool is MultiStakingRewardsERC4626, IStabilityPool {
  /// @inheritdoc IStabilityPool
  IERC20 public zai;

  /// @inheritdoc IStabilityPool
  bytes32 public MANAGER_ROLE;

  /// @inheritdoc IStabilityPool
  uint256 public WITHDRAWAL_DELAY;

  /// @inheritdoc IStabilityPool
  mapping(address => uint256) public withdrawalTimestamp;

  /// @inheritdoc IStabilityPool
  mapping(address => uint256) public withdrawalAmount;

  /// @inheritdoc IStabilityPool
  function initialize(
    address _zai,
    uint256 withdrawalDelay,
    address _governance,
    address _rewardToken1,
    address _rewardToken2,
    uint256 _rewardsDuration
  ) external reinitializer(1) {
    _MultiStakingRewardsERC4626_init(
      "Stability Pool ZAI",
      "sZAI",
      _zai, // address _stakingToken,
      _governance, // address _governance,
      _rewardToken1, // address _rewardToken1,
      _rewardToken2, // address _rewardToken2,
      _rewardsDuration // uint256 _rewardsDuration
    );

    WITHDRAWAL_DELAY = withdrawalDelay;
    zai = IERC20(_zai);
    MANAGER_ROLE = keccak256("MANAGER_ROLE");
  }

  /// @inheritdoc IStabilityPool
  function queueWithdrawal(uint256 shares) external {
    require(shares <= balanceOf(msg.sender), "insufficient balance");
    withdrawalTimestamp[msg.sender] = block.timestamp + WITHDRAWAL_DELAY;
    withdrawalAmount[msg.sender] = shares;
    emit StabilityPoolEvents.WithdrawalQueueUpdated(shares, withdrawalTimestamp[msg.sender], msg.sender);
  }

  /// @inheritdoc IStabilityPool
  function cancelWithdrawal() external {
    withdrawalTimestamp[msg.sender] = 0;
    withdrawalAmount[msg.sender] = 0;
    emit StabilityPoolEvents.WithdrawalQueueUpdated(0, 0, msg.sender);
  }

  /// @inheritdoc IStabilityPool
  function coverBadDebt(uint256 amount) external onlyRole(MANAGER_ROLE) {
    zai.transfer(msg.sender, amount);
    emit StabilityPoolEvents.BadDebtCovered(amount, msg.sender);
  }

  function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares) internal override {
    uint256 amount = withdrawalAmount[caller];

    require(withdrawalTimestamp[caller] <= block.timestamp, "withdrawal not ready");
    require(withdrawalTimestamp[caller] > 0, "no withdrawal qeued");
    require(shares == amount && amount > 0, "invalid shares");

    withdrawalTimestamp[caller] = 0;
    withdrawalAmount[caller] = 0;

    super._withdraw(caller, receiver, owner, assets, shares);

    emit StabilityPoolEvents.WithdrawalQueueUpdated(0, 0, caller);
  }
}
