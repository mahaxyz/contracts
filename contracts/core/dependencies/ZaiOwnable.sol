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

pragma solidity 0.8.19;

import "../interfaces/IZaiCore.sol";

/**
    @title Zai Ownable
    @notice Contracts inheriting `ZaiOwnable` have the same owner as `ZaiCore`.
            The ownership cannot be independently modified or renounced.
 */
contract ZaiOwnable {
    IZaiCore public immutable ZAI_CORE;

    constructor(address _zaiCore) {
        ZAI_CORE = IZaiCore(_zaiCore);
    }

    modifier onlyOwner() {
        require(msg.sender == ZAI_CORE.owner(), "Only owner");
        _;
    }

    function owner() public view returns (address) {
        return ZAI_CORE.owner();
    }

    function guardian() public view returns (address) {
        return ZAI_CORE.guardian();
    }
}
