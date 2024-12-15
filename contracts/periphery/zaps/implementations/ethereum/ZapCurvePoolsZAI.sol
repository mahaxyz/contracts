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
import {ZapBaseEthereum, ZapCurvePoolBase} from "./ZapCurvePoolBase.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapCurvePoolsZAI is ZapCurvePoolBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  address public odos;
  IERC4626 public szai;

  constructor(address _staking, address _psm, address _szai, address _odos) ZapBaseEthereum(_staking, _psm) {
    szai = IERC4626(_szai);
    odos = _odos;
    szai.approve(address(pool), type(uint256).max);
    zai.approve(address(pool), type(uint256).max);
    zai.approve(address(szai), type(uint256).max);
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

    if (address(swapAsset) != address(collateral)) {
      // swap on odos to 100% collateral
      (bool success,) = odos.call{value: msg.value}(odosCallData);
      require(success, "odos call failed");
    }

    // convert collateral for zai
    uint256 zaiMinted = psm.mintAmountIn(collateral.balanceOf(me));
    psm.mint(me, zaiMinted);

    // convert 50% into sZAI
    szai.deposit(zaiMinted / 2, me);

    // add liquidity with maha and ZAI
    uint256 zaiAmount = zai.balanceOf(me);
    uint256 szaiMinted = szai.balanceOf(me);
    _addLiquidity(zaiAmount, szaiMinted, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(me), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
    _sweep(swapAsset);
    _sweep(szai);

    emit Zapped(msg.sender, zaiAmount, szaiMinted, pool.balanceOf(msg.sender));
  }

  function _addLiquidity(uint256 zaiAmt, uint256 collatAmt, uint256 minLp) internal virtual override {
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = zaiAmt;
    amounts[1] = collatAmt;
    ICurveStableSwapNG(address(pool)).add_liquidity(amounts, minLp, me);
  }
}
