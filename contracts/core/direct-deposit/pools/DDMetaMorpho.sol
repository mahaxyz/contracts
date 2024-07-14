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

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IDDPool, DDBase} from "../DDBase.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/extensions/AccessControlEnumerableUpgradeable.sol";

/**
 * @title MetaMorpho Direct Deposit Module
 * @author maha.xyz
 * @notice A direct deposit module that manages a morpho vault
 */
contract DDMetaMorpho is AccessControlEnumerableUpgradeable, DDBase {
    uint256 public exited;

    IERC4626 public vault;

    function initialize(
        address _hub,
        address _zai,
        address _vault
    ) external reinitializer(1) {
        __DDBBase_init(_zai, _hub);
        __AccessControl_init();

        vault = IERC4626(_vault);

        require(_hub != address(0), "DDMetaMorpho/zero-address");
        require(_zai != address(0), "DDMetaMorpho/zero-address");
        require(_vault != address(0), "DDMetaMorpho/zero-address");
        require(
            IERC4626(_vault).asset() == _zai,
            "DDMetaMorpho/vault-asset-is-not-zai"
        );

        zai.approve(_vault, type(uint256).max);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// https://github.com/morpho-org/metamorpho/blob/fcf3c41d9c113514c9af0bbf6298e88a1060b220/src/MetaMorpho.sol#L531
    /// @inheritdoc IDDPool
    function deposit(uint256 wad) external override onlyHub {
        vault.deposit(wad, address(this));
    }

    /// https://github.com/morpho-org/metamorpho/blob/fcf3c41d9c113514c9af0bbf6298e88a1060b220/src/MetaMorpho.sol#L557
    /// @inheritdoc IDDPool
    function withdraw(uint256 wad) external override onlyHub {
        vault.withdraw(wad, msg.sender, address(this));
    }

    /// @inheritdoc IDDPool
    function preDebtChange() external override {}

    /// @inheritdoc IDDPool
    function postDebtChange() external override {}

    /// @inheritdoc IDDPool
    function assetBalance() external view returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    /// @inheritdoc IDDPool
    function maxDeposit() external view returns (uint256) {
        return vault.maxDeposit(address(this));
    }

    /// @inheritdoc IDDPool
    function maxWithdraw() external view returns (uint256) {
        return vault.maxWithdraw(address(this));
    }

    /// @inheritdoc IDDPool
    function redeemable() external view returns (address) {
        return address(vault);
    }
}
