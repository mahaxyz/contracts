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

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IDDPool} from "../../interfaces/core/IDDPool.sol";
import {IZaiStablecoin} from "../../interfaces/IZaiStablecoin.sol";

abstract contract DDBBase is IDDPool {
    /// @inheritdoc IDDPool
    IZaiStablecoin public zai;

    /// @inheritdoc IDDPool
    address public hub;

    function __DDBBase_init(address _zai, address _hub) internal {
        zai = IZaiStablecoin(_zai);
        hub = _hub;
    }

    modifier onlyHub() {
        if (msg.sender != hub) revert NotAuthorized();
        _;
    }
}
