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

contract ZapAerodromePoolUSDC is ZapAerodromeBase {
  constructor(address _staking, address _bridge, address _router) ZapAerodromeBase(_staking, _bridge, _router) {
    // nothing
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens
   * @dev This function is used when the user only has collateral tokens.
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) external {
    collateral.transferFrom(msg.sender, me, collateralAmount);

    uint256 price = collateral.balanceOf(address(pool)) * 1e30 / zai.balanceOf(address(pool));
    if (price < 90 * 1e16) {
      // < 0.99
      _zapDepegged(collateralAmount, minLpAmount);
    } else {
      _zapNormal(collateralAmount, minLpAmount);
    }
  }

  function _zapDepegged(uint256 collateralAmount, uint256 minLpAmount) internal {
    IAerodromeRouter.Route memory route =
      IAerodromeRouter.Route({from: address(collateral), to: address(zai), stable: true, factory: factory});

    IAerodromeRouter.Route[] memory routes = new IAerodromeRouter.Route[](1);
    routes[0] = route;

    router.swapExactTokensForTokens(
      collateralAmount / 2, //       uint256 amountIn,
      collateralAmount / 2 * 1e12, // uint256 amountOutMin,
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
