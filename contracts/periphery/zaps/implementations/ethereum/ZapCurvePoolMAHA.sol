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
import {ZapBaseEthereum, ZapCurvePoolBase} from "./ZapCurvePoolBase.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapCurvePoolMAHA is ZapCurvePoolBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  IERC20 public maha;
  address public odos;

  constructor(address _staking, address _psm, IERC20 _maha, address _odos) ZapBaseEthereum(_staking, _psm) {
    maha = IERC20(_maha);
    odos = _odos;
    maha.approve(address(pool), type(uint256).max);
    zai.approve(address(pool), type(uint256).max);
  }

  function zapWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minLpAmount,
    bytes memory odosCallData
  ) external payable {
    if (swapAsset != IERC20(address(0))) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      swapAsset.forceApprove(odos, swapAmount);
    }

    // swap on odos to 50-50 collateral and maha
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "odos call failed");

    // convert collateral for zai
    uint256 zaiToMint = psm.mintAmountIn(collateral.balanceOf(me));
    psm.mint(address(this), zaiToMint);

    // add liquidity with maha and ZAI
    uint256 mahaAmount = maha.balanceOf(me);
    _addLiquidity(zaiToMint, mahaAmount, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(swapAsset);
    _sweep(maha);

    emit Zapped(msg.sender, mahaAmount, zaiToMint, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual override {
    uint256[2] memory amounts; // = new uint256[2]();
    amounts[0] = zaiAmt;
    amounts[1] = collatAmt;
    ICurveTwoCrypto(address(pool)).add_liquidity(amounts, minLp);
  }
}
