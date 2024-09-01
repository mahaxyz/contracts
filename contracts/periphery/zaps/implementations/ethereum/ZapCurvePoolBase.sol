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

import {ZapBaseEthereum} from "./ZapBaseEthereum.sol";

/**
 * @title ZapCurvePool
 * @dev This contract allows users to perform a Zap operation by swapping collateral for zai tokens, adding liquidity to
 * curve LP, and staking the LP tokens.
 */
abstract contract ZapCurvePoolBase is ZapBaseEthereum {
  /**
   * @notice Zaps ZAI and collateral into LP tokens
   * @dev This function is used when the user already has ZAI tokens.
   * @param zaiAmount The amount of ZAI to zap
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapWithZaiIntoLP(uint256 zaiAmount, uint256 collateralAmount, uint256 minLpAmount) external {
    // fetch tokens
    if (zaiAmount > 0) zai.transferFrom(msg.sender, me, zaiAmount);
    if (collateralAmount > 0) collateral.transferFrom(msg.sender, me, collateralAmount);

    // add liquidity
    _addLiquidity(zaiAmount, collateralAmount, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);

    emit Zapped(msg.sender, collateralAmount, zaiAmount, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual;
}
