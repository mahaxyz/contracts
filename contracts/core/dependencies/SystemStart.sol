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

import {IZaiCore} from "../../interfaces/IZaiCore.sol";
import {ISystemStart} from "../../interfaces/ISystemStart.sol";

/**
 * @title Zai System Start Time
 * @author maha.xyz
 * @dev Provides a unified `startTime` and `getWeek`, used for emissions.
 */
contract SystemStart is ISystemStart {
    uint256 immutable startTime;

    constructor(address zaiCore) {
        startTime = IZaiCore(zaiCore).startTime();
    }

    /// @inheritdoc ISystemStart
    function getWeek() public view returns (uint256 week) {
        return (block.timestamp - startTime) / 1 weeks;
    }
}
