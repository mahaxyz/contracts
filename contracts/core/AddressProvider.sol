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

import {IAddressProvider} from "../interfaces/core/IAddressProvider.sol";
import {IZaiStablecoin} from "../interfaces/IZaiStablecoin.sol";

contract AddressProvider is IAddressProvider {
    IZaiStablecoin public zai;

    // todo
    function deposit(address destination, uint256 amount) external {
        zai.mint(destination, amount);
    }

    function withdraw(address destination, uint256 amount) external {}
}
