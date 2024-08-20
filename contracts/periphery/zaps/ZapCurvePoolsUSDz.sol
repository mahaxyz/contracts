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

import {IERC4626, ZapCurvePoolBase} from "./ZapCurvePoolBase.sol";

contract ZapCurvePoolsUSDz is ZapCurvePoolBase {
  IERC4626 public stakingUSDz;

  constructor(address _staking, address _stakingUSDz, address _psm) ZapCurvePoolBase(_staking, _psm) {
    stakingUSDz = IERC4626(_stakingUSDz);
    zai.approve(address(stakingUSDz), type(uint256).max);
    stakingUSDz.approve(address(pool), type(uint256).max);
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

    // convert 100% collateral for zai
    uint256 zaiAmount = collateralAmount * decimalOffset;
    psm.mint(address(this), zaiAmount);

    // stake 50% collateral for sUSDz
    stakingUSDz.deposit(zaiAmount / 2, me);

    // add liquidity
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = zaiAmount / 2;
    amounts[1] = zaiAmount / 2;

    pool.add_liquidity(amounts, minLpAmount, me);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(stakingUSDz);

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }
}
