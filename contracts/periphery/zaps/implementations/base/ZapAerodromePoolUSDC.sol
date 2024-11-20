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

contract ZapAerodromePoolUSDC is ZapAerodromeBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  address public odos;

  constructor(
    address _staking,
    address _bridge,
    address _router,
    address _odos
  ) ZapAerodromeBase(_staking, _bridge, _router) {
    // nothing
    odos = _odos;
  }

  /**
   * @notice Wrapper function for directly zapping with USDC collateral
   * @param collateralAmount The amount of USDC to deposit into the LP
   * @param minLpAmount The minimum LP tokens to receive after zapping
   */
  function zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) public {
    collateral.safeTransferFrom(msg.sender, me, collateralAmount);
    _zapIntoLP(collateralAmount, minLpAmount);
  }

  /**
   * @notice Internal function to zap collateral into ZAI LP tokens
   * @dev Decides which zap function to use based on pool price stability
   * @param collateralAmount The amount of USDC available for LP zapping
   * @param minLpAmount The minimum LP tokens to receive after zapping
   */
  function _zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) internal {
    uint256 price = (collateral.balanceOf(address(pool)) * 1e30) / zai.balanceOf(address(pool));
    if (price < 90 * 1e16) {
      // < 0.99
      _zapDepegged(collateralAmount, minLpAmount);
    } else {
      _zapNormal(collateralAmount, minLpAmount);
    }
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens with any token by using Odos
   * @param swapAsset The asset to swap into USDC using Odos
   * @param swapAmount The amount of `swapAsset` to swap
   * @param minLpAmount The minimum LP tokens to receive after zapping
   * @param odosCallData Encoded Odos swap data
   */
  function zapIntoLPWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minLpAmount,
    bytes memory odosCallData
  ) external payable {
    if (address(swapAsset) != address(0)) {
      // Transfer swapAsset from user
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      // Approve Odos to spend swapAsset and perform the swap
      swapAsset.approve(odos, swapAmount);
    }

    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "Odos swap failed");

    // Now we have USDC in contract, call internal zap function
    _zapIntoLP(collateral.balanceOf(me), minLpAmount);
  }

  function _zapDepegged(uint256 collateralAmount, uint256 minLpAmount) internal {
    IAerodromeRouter.Route memory route =
      IAerodromeRouter.Route({from: address(collateral), to: address(zai), stable: true, factory: factory});

    IAerodromeRouter.Route[] memory routes = new IAerodromeRouter.Route[](1);
    routes[0] = route;

    router.swapExactTokensForTokens(
      collateralAmount / 2, //       uint256 amountIn,
      (collateralAmount / 2) * 1e12, // uint256 amountOutMin,
      routes, // Route[] calldata routes,
      me, // address to,
      block.timestamp // uint256 deadline
    );

    router.addLiquidity(
      address(collateral), address(zai), true, collateralAmount / 2, zai.balanceOf(me), 0, 0, me, block.timestamp
    );

    require(pool.balanceOf(me) >= minLpAmount, "!insufficient");

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(me), msg.sender);

    // sweep any dust
    _sweep(collateral);

    emit Zapped(msg.sender, collateralAmount, 0, pool.balanceOf(msg.sender));
  }

  function _zapNormal(uint256 collateralAmount, uint256 minLpAmount) internal {
    // convert 50% collateral for zai
    uint256 zaiAmount = bridge.deposit(collateralAmount / 2);

    router.addLiquidity(
      address(collateral), address(zai), true, collateralAmount / 2, zaiAmount, 0, 0, me, block.timestamp
    );

    require(pool.balanceOf(me) >= minLpAmount, "!insufficient");

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(me), msg.sender);

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }

  function zapOutOfLP(uint256 amount, uint256 minCollateralAmount) external {
    staking.withdraw(amount, msg.sender, me);

    IAerodromeRouter(address(pool)).removeLiquidity(
      address(collateral), address(zai), true, pool.balanceOf(me), 0, 0, me, block.timestamp
    );

    IAerodromeRouter.Route memory route = IAerodromeRouter.Route({
      from: address(zai),
      to: address(collateral),
      stable: true,
      factory: IAerodromeRouter(address(pool)).defaultFactory()
    });

    // swap usdc into zai
    IAerodromeRouter.Route[] memory routes = new IAerodromeRouter.Route[](1);
    routes[0] = route;
    router.swapExactTokensForTokens(zai.balanceOf(me), 0, routes, me, block.timestamp);

    require(collateral.balanceOf(me) >= minCollateralAmount, "!insufficient");

    // sweep any dust
    _sweep(zai);
    _sweep(collateral);
  }
}
