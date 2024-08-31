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

import {ICurveTwoCrypto} from "../../../../interfaces/periphery/curve/ICurveTwoCrypto.sol";
import {ZapBase, ZapCurvePoolBase} from "../../ZapCurvePoolBase.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapCurvePoolMAHA is ZapCurvePoolBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  IERC20 public maha;
  address public odos;

  constructor(address _staking, IERC20 _maha, address _psm, address _odos) ZapBase(_staking, _psm) {
    maha = IERC20(_maha);
    odos = _odos;
    maha.approve(address(pool), type(uint256).max);
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens
   * @dev This function is used when the user only has collateral tokens.
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) public {
    collateral.safeTransferFrom(msg.sender, me, collateralAmount);
    _zapIntoLP(collateralAmount, minLpAmount);
  }

  function zapIntoLPWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minLpAmount,
    bytes memory odosCallData
  ) external payable {
    if (swapAsset != IERC20(address(0))) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
    }

    // swap on odos
    swapAsset.approve(odos, swapAmount);
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "odos call failed");

    _zapIntoLP(collateral.balanceOf(me), minLpAmount);
  }

  function _zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) internal {
    // convert 100% collateral for zai
    uint256 zaiAmount = collateralAmount * decimalOffset;
    psm.mint(address(this), zaiAmount);

    // add liquidity
    _addLiquidity(zaiAmount, 0, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(IERC20Metadata(address(maha)));

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual override {
    uint256[2] memory amounts; // = new uint256[2]();
    amounts[0] = collatAmt;
    amounts[1] = zaiAmt;
    ICurveTwoCrypto(address(pool)).add_liquidity(amounts, minLp);
  }
}
