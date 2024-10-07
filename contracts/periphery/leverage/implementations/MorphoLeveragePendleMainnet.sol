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

pragma solidity 0.8.21;

import {ILoopingStrategy} from "../../../interfaces/periphery/leverage/ILoopingStrategy.sol";
import {IMorpho, MorphoLeverageMainnet} from "../MorphoLeverageMainnet.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MorphoLeveragePendleMainnet
/// @author maha.xyz
/// @notice Leverages contract on Morpho with Pendle PT Tokens
contract MorphoLeveragePendleMainnet is MorphoLeverageMainnet {
  using SafeERC20 for IERC20;

  constructor(
    address _morpho,
    IMorpho.MarketParams memory _marketParams
  ) MorphoLeverageMainnet(_morpho, _marketParams, address(0)) {}
}
