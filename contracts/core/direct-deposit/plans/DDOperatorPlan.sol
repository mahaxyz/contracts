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

pragma solidity 0.8.20;

import {AccessControlDefaultAdminRules} from "@openzeppelin/contracts/access/extensions/AccessControlDefaultAdminRules.sol";
import {IDDPlan} from "../../../interfaces/core/IDDPlan.sol";

/**
 * @title Direct Deposit Operator Plan
 * @notice An operator sets the desired target assets for a simple vault
 */
contract DDOperatorPlan is AccessControlDefaultAdminRules, IDDPlan {
    uint256 public enabled;
    uint256 public targetAssets;
    bytes32 public OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    constructor(
        uint48 _initialDelay,
        address _governance
    ) AccessControlDefaultAdminRules(_initialDelay, _governance) {
        // nothing
    }

    function setTargetAssets(uint256 value) external onlyRole(OPERATOR_ROLE) {
        targetAssets = value;
    }

    /// @inheritdoc IDDPlan
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
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(OPERATOR_ROLE, msg.sender),
            "!role"
        );
        enabled = 0;
        emit Disable();
    }
}
