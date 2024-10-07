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

import {ISwapper} from "../../interfaces/periphery/leverage/ISwapper.sol";
import {IWNative} from "../../interfaces/periphery/leverage/IWNative.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract BaseLeverage is ReentrancyGuard, ILoopingStrategy {
  using SafeERC20 for IERC20;

  address public immutable WNATIVE;

  constructor(address _wnative) {
    WNATIVE = _wnative;
  }

  function increasePos(IncreasePosParams calldata params) external override {
    // transfer tokenIn from msg.sender to address this
    IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amtIn);
    _increasePos(params);
  }

  function increasePosNative(IncreasePosParams calldata params) external payable nonReentrant {
    require(params.tokenIn == WNATIVE, "BaseLeverage: invalid tokenIn");
    require(msg.value == params.amtIn, "BaseLeverage: invalid msg.value");
    // deposit native token to wnative
    IWNative(WNATIVE).deposit{value: msg.value}();
    _increasePos(params);
  }

  function decreasePos(DecreasePosParams calldata params) external nonReentrant {
    uint256 amtOut = _decreasePos(params);
    // transfer tokenOut to msg.sender
    IERC20(params.tokenOut).safeTransfer(msg.sender, amtOut);
  }

  function decreasePosNative(DecreasePosParams calldata params) external nonReentrant {
    require(params.tokenOut == WNATIVE, "BaseLeverage: invalid tokenOut");
    uint256 amtOut = _decreasePos(params);
    // withdraw wnative to msg.sender
    IWNative(WNATIVE).withdraw(amtOut);
    (bool success,) = payable(msg.sender).call{value: amtOut}("");
    require(success, "BaseLeverage: transfer native failed");
  }

  function repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) external nonReentrant {
    _repayDebtWithCollateral(params);
  }

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

  function _ensureApprove(address _token, address _to, uint256 _amt) internal {
    if (IERC20(_token).allowance(address(this), _to) < _amt) {
      IERC20(_token).forceApprove(_to, type(uint256).max);
    }
  }

  function _increasePos(IncreasePosParams calldata params) internal virtual;

  function _repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) internal virtual;

  function _decreasePos(DecreasePosParams memory params) internal virtual returns (uint256 amtOut);

  function _reducePos(
    address collPool,
    uint256 collAmt,
    address borrToken,
    uint256 repayAmt,
    address onBehalfOf
  ) internal virtual returns (uint256);

  receive() external payable {
    require(msg.sender == WNATIVE, "BaseLeverage: not wnative");
  }
}
