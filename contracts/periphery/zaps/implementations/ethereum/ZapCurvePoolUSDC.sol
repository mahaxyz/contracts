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

import {ICurveStableSwapNG} from "../../../../interfaces/periphery/curve/ICurveStableSwapNG.sol";
import {ZapBase, ZapCurvePoolBase} from "../../ZapCurvePoolBase.sol";

contract ZapCurvePoolUSDC is ZapCurvePoolBase {
  constructor(address _staking, address _psm) ZapBase(_staking, _psm) {
    // nothing
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens
   * @dev This function is used when the user only has collateral tokens.
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) external {
    // fetch tokens
    collateral.transferFrom(msg.sender, me, collateralAmount);

    // convert 50% collateral for zai
    uint256 zaiAmount = collateralAmount * decimalOffset / 2;
    psm.mint(address(this), zaiAmount);

    // add liquidity
    _addLiquidity(zaiAmount, collateralAmount / 2, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual override {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = collatAmt / 2;
    amounts[1] = zaiAmt;
    ICurveStableSwapNG(address(pool)).add_liquidity(amounts, minLp, me);
  }
}
