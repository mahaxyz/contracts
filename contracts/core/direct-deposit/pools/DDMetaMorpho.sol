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

import {IDDPool} from "../../../interfaces/core/IDDPool.sol";
import {IZaiStablecoin} from "../../../interfaces/IZaiStablecoin.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

abstract contract DDMetaMorpho is AccessControlEnumerable, IDDPool {
    address public hub;
    uint256 public exited;

    IERC4626 public immutable vault;
    IZaiStablecoin public immutable zai;

    constructor(address _hub, address _zai, address _vault) {
        zai = IZaiStablecoin(_zai);
        vault = IERC4626(_vault);

        require(_hub != address(0), "D3M4626TypePool/zero-address");
        require(_zai != address(0), "D3M4626TypePool/zero-address");
        require(_vault != address(0), "D3M4626TypePool/zero-address");
        require(
            IERC4626(_vault).asset() == _zai,
            "D3M4626TypePool/vault-asset-is-not-zai"
        );

        zai.approve(_vault, type(uint256).max);
        hub = _hub;
        // vat = VatLike(D3mHubLike(_hub).vat());
        // vat.hope(_hub);

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyHub() {
        require(msg.sender == hub, "D3M4626TypePool/only-hub");
        _;
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
    function exit(address dst, uint256 wad) external override onlyHub {
        uint256 exited_ = exited;
        exited = exited_ + wad;
        // uint256 amt = (wad * vault.balanceOf(address(this))) /
        //     (D3mHubLike(hub).end().Art(ilk) - exited_);
        // require(vault.transfer(dst, amt), "D3M4626TypePool/transfer-failed");
    }

    /// @inheritdoc IDDPool
    function quit(address dst) external onlyRole(DEFAULT_ADMIN_ROLE) {
        // require(vat.live() == 1, "D3M4626TypePool/no-quit-during-shutdown");
        // require(
        //     vault.transfer(dst, vault.balanceOf(address(this))),
        //     "D3M4626TypePool/transfer-failed"
        // );
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
