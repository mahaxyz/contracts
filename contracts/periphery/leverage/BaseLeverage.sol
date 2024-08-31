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

  function _ensureApprove(address _token, address _to, uint256 _amt) internal {
    if (IERC20(_token).allowance(address(this), _to) < _amt) {
      IERC20(_token).forceApprove(_to, type(uint256).max);
    }
  }

  receive() external payable {
    require(msg.sender == WNATIVE, "BaseLeverage: not wnative");
  }
}
