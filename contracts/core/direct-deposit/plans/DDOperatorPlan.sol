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

import {IDDPlan} from "../../../interfaces/core/IDDPlan.sol";
import {AccessControlDefaultAdminRules} from
  "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";

/**
 * @title Direct Deposit Operator Plan
 * @notice An operator sets the desired target assets for a simple vault
 */
contract DDOperatorPlan is AccessControlDefaultAdminRules, IDDPlan {
  uint256 public enabled = 1;
  uint256 public targetAssets;
  bytes32 public immutable OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  constructor(
    uint48 _initialDelay,
    address _governance,
    uint256 _targetAssets
  ) AccessControlDefaultAdminRules(_initialDelay, _governance) {
    targetAssets = _targetAssets;
  }

  function setTargetAssets(uint256 value) external onlyRole(OPERATOR_ROLE) {
    targetAssets = value;
  }

  /// @inheritdoc IDDPlan
  /// @dev The `currentAssets` arguement is not used in this plan.
  function getTargetAssets(uint256) external view override returns (uint256) {
    if (enabled == 0) return 0;
    return targetAssets;
  }

  /// @inheritdoc IDDPlan
  function active() public view override returns (bool) {
    return enabled == 1;
  }

  /// @inheritdoc IDDPlan
  function disable() external override {
    require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender) || hasRole(OPERATOR_ROLE, msg.sender), "!role");
    enabled = 0;
    emit Disable();
  }
}
