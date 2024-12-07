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

import {ICurveStableSwapNG, IERC20} from "../../../../interfaces/periphery/curve/ICurveStableSwapNG.sol";
import {ZapBaseEthereum, ZapCurvePoolBase} from "./ZapCurvePoolBase.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapCurvePoolUSDC is ZapCurvePoolBase {
  using SafeERC20 for IERC20;

  IERC20 public usdc;
  address public odos;

  constructor(address _staking, address _psm, address _usdc, address _odos) ZapBaseEthereum(_staking, _psm) {
    usdc = IERC20(_usdc);
    odos = _odos;
    usdc.approve(address(pool), type(uint256).max);
    zai.approve(address(pool), type(uint256).max);
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens
   * @dev This function is used when the user only has collateral tokens.
   */
  function zapWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minLpAmount,
    bytes memory odosCallData
  ) external payable {
    if (swapAsset != IERC20(address(0))) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      swapAsset.approve(odos, swapAmount);
    }

    // swap on odos to 50-50 collateral and USDC
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "odos call failed");

    // convert collateral for zai
    uint256 zaiToMint = psm.mintAmountIn(collateral.balanceOf(me));
    psm.mint(address(this), zaiToMint);

    // add liquidity with USDC and ZAI
    uint256 usdcAmount = usdc.balanceOf(me);
    _addLiquidity(zaiToMint, usdcAmount, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(swapAsset);
    _sweep(usdc);

    emit Zapped(msg.sender, usdcAmount, zaiToMint, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual override {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = collatAmt;
    amounts[1] = zaiAmt;
    ICurveStableSwapNG(address(pool)).add_liquidity(amounts, minLp, me);
  }
}
