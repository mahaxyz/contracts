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

import {
  ERC4626Upgradeable, IERC20
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

contract StabilityPool is AccessControlEnumerableUpgradeable, ERC4626Upgradeable, IStabilityPool {
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
  function initialize(address _zai, uint256 withdrawalDelay, address _govenrance) external reinitializer(1) {
    __AccessControlEnumerable_init();
    __ERC20_init("Stability Pool ZAI", "sZAI");
    __ERC4626_init_unchained(zai);

    WITHDRAWAL_DELAY = withdrawalDelay;
    zai = IERC20(_zai);
    MANAGER_ROLE = keccak256("MANAGER_ROLE");

    _grantRole(DEFAULT_ADMIN_ROLE, _govenrance);
  }

  /// @inheritdoc IStabilityPool
  function queueWithdrawal(uint256 shares) external {
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
    require(withdrawalTimestamp[caller] <= block.timestamp, "withdrawal not ready");
    withdrawalTimestamp[msg.sender] = 0;

    uint256 amount = withdrawalAmount[msg.sender];
    withdrawalAmount[msg.sender] = 0;
    require(shares == amount, "invalid shares");

    super._withdraw(caller, receiver, owner, assets, shares);

    emit StabilityPoolEvents.WithdrawalQueueUpdated(0, 0, msg.sender);
  }
}
