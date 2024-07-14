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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library PSMEventsLib {
    event Mint(
        address indexed destination,
        uint256 indexed shares,
        uint256 indexed amount,
        uint256 newDebt,
        uint256 supplyCap,
        address sender
    );

    event RateUpdated(
        uint256 indexed oldRate,
        uint256 indexed newRate,
        address sender
    );

    event Redeem(
        address indexed destination,
        uint256 indexed shares,
        uint256 indexed amount,
        uint256 newDebt,
        uint256 supplyCap,
        address sender
    );

    event SupplyCapUpdated(
        uint256 indexed _newSupplyCap,
        uint256 indexed _newDebtCap,
        uint256 _oldSupplyCap,
        uint256 _oldDebtCap,
        address sender
    );
}
