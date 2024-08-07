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

import {IERC20Metadata, ZapCurvePoolBase} from "./ZapCurvePoolBase.sol";

contract ZapCurvePoolMAHA is ZapCurvePoolBase {
  IERC20Metadata public maha;

  constructor(address _staking, address _maha, address _psm) ZapCurvePoolBase(_staking, _psm) {
    maha = IERC20Metadata(_maha);
    maha.approve(address(pool), type(uint256).max);
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
    uint256 zaiAmount = collateralAmount * decimalOffset;
    psm.mint(address(this), zaiAmount);

    // convert 50% collateral for maha
    // todo

    // add liquidity
    // uint256[2] memory amounts;
    // amounts[0] = collateralAmount / 2;
    // amounts[1] = collateralAmount / 2;
    // router.add_liquidity(address(pool), amounts, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(maha);

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }
}
