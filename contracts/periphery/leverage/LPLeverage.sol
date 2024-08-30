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

import {ILoopingStrategy} from "../../interfaces/periphery/leverage/ILoopingStrategy.sol";
import {BaseLeverage, BaseLeverageWithSwap} from "./BaseLeverageWithSwap.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title MorphoLeverage
/// @author maha.xyz
/// @notice Leverages contract on Morpho with LP tokens
abstract contract MorphoLeverage is BaseLeverageWithSwap {
  using SafeERC20 for IERC20;

  address public immutable MORPHO;

  constructor(address _morpho, address _wnative) BaseLeverage(_wnative) {
    MORPHO = _morpho;
  }

  function _repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) internal override {
    // todo
  }

  function _increasePos(IncreasePosParams calldata params) internal override {
    // todo
  }

  function _decreasePos(DecreasePosParams memory params) internal override returns (uint256 amtOut) {
    // todo
  }
}
