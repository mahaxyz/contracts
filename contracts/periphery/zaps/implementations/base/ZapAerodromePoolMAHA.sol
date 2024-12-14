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

import {IAerodromePool} from "../../../../interfaces/periphery/dex/IAerodromePool.sol";
import {IAerodromeRouter} from "../../../../interfaces/periphery/dex/IAerodromeRouter.sol";
import {ZapAerodromeBase} from "./ZapAerodromeBase.sol";

import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapAerodromePoolMAHA is ZapAerodromeBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  address public odos;
  IERC20 public maha;

  constructor(
    address _staking,
    address _bridge,
    address _router,
    address _odos,
    address _maha
  ) ZapAerodromeBase(_staking, _bridge, _router) {
    odos = _odos;
    maha = IERC20(_maha);
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens with any token by using Odos
   * @param swapAsset The asset to swap into USDC using Odos
   * @param swapAmount The amount of `swapAsset` to swap
   * @param minLpAmount The minimum LP tokens to receive after zapping
   * @param odosCallData Encoded Odos swap data
   */
  function zapWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minLpAmount,
    bytes memory odosCallData
  ) external payable {
    // Transfer swapAsset from user
    if (address(swapAsset) != address(0)) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      swapAsset.forceApprove(odos, swapAmount);
    }

    // Approve Odos to spend swapAsset and perform the swap
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "Odos swap failed");

    // convert USDC into ZAI
    uint256 zaiAmount = bridge.deposit(collateral.balanceOf(me));
    uint256 mahaAmount = maha.balanceOf(me);

    // add liquidity to the pool
    router.addLiquidity(address(collateral), address(zai), true, mahaAmount, zaiAmount, 0, 0, me, block.timestamp);
    require(pool.balanceOf(me) >= minLpAmount, "!insufficient");

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(me), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(maha);
    _sweep(collateral);

    emit Zapped(msg.sender, mahaAmount, zaiAmount, pool.balanceOf(msg.sender));
  }
}
