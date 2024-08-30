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

// import {ILoopingStrategy} from "../../interfaces/periphery/leverage/ILoopingStrategy.sol";
import {ISwapper} from "../../interfaces/periphery/leverage/ISwapper.sol";
// import {IWNative} from "../../interfaces/periphery/leverage/IWNative.sol";

import {BaseLeverage} from "./BaseLeverage.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseLeverageWithSwap is BaseLeverage {
  using SafeERC20 for IERC20;

  function _swapExactIn(
    address swapper,
    address from,
    address to,
    uint256 amtIn,
    uint256 minAmtOut,
    bytes memory data
  ) internal {
    ISwapper.SwapExactInParams memory swapExactInParams = ISwapper.SwapExactInParams({from: from, to: to, data: data});
    // transfer token to swapper
    IERC20(from).safeTransfer(swapper, amtIn);
    // call swap function on swapper
    ISwapper(swapper).swapExactIn(swapExactInParams);
    // verify that the swap was successful
    uint256 amtOut = IERC20(to).balanceOf(address(this));
    require(amtOut >= minAmtOut, "BaseLeverageWithSwap: insufficient amtOut");
    emit Swap(swapper, from, to, amtIn, amtOut);
  }

  function _swapExactOut(
    address swapper,
    address from,
    address to,
    uint256 amtOut,
    uint256 maxAmtIn,
    bytes memory data
  ) internal {
    ISwapper.SwapExactOutParams memory swapExactOutParams = ISwapper.SwapExactOutParams({
      from: from,
      to: to,
      amtOut: amtOut - IERC20(to).balanceOf(address(this)),
      data: data
    });
    // transfer token to swapper
    uint256 tokenInBalBf = IERC20(from).balanceOf(address(this));
    IERC20(from).safeTransfer(swapper, tokenInBalBf);
    // call swap function on swapper
    ISwapper(swapper).swapExactOut(swapExactOutParams);
    // verify that the swap was successful (slippage maxAmtIn)
    uint256 amtIn = tokenInBalBf - IERC20(from).balanceOf(address(this));
    require(amtIn <= maxAmtIn, "BaseLeverageWithSwap: exceed maxAmtIn");
    require(IERC20(to).balanceOf(address(this)) >= amtOut, "BaseLeverageWithSwap: invalid amtOut");
    emit Swap(swapper, from, to, amtIn, amtOut);
  }
}
