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
import {IZaiOwnable} from "../../interfaces/IZaiOwnable.sol";

/**
 * @title Zai Ownable
 * @author maha.xyz
 * @notice Contracts inheriting `ZaiOwnable` have the same owner as `ZaiCore`.
 * The ownership cannot be independently modified or renounced.
 */
contract ZaiOwnable is IZaiOwnable {
    /// @inheritdoc IZaiOwnable
    IZaiCore public immutable ZAI_CORE;

    constructor(address core) {
        ZAI_CORE = IZaiCore(core);
    }

    modifier onlyOwner() {
        require(msg.sender == ZAI_CORE.owner(), "Only owner");
        _;
    }

    /// @inheritdoc IZaiOwnable
    function owner() public view returns (address) {
        return ZAI_CORE.owner();
    }

    /// @inheritdoc IZaiOwnable
    function guardian() public view returns (address) {
        return ZAI_CORE.guardian();
    }
}
