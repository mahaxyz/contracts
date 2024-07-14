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

import {IZaiStablecoin} from "../IZaiStablecoin.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IPegStabilityModule {
    function zai() external returns (IZaiStablecoin);

    function collateral() external returns (IERC20);

    function supplyCap() external returns (uint256);

    function debtCap() external returns (uint256);

    function debt() external returns (uint256);

    function rate() external returns (uint256);

    function mint(address destination, uint256 amount) external;

    function redeem(address destination, uint256 amount) external;

    function updateCaps(uint256 _supplyCap, uint256 _debtCap) external;

    function updateRate(uint256 _newRate) external;

    function toCollateralAmount(
        uint256 _amount
    ) external view returns (uint256);
}
