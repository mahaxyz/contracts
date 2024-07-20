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

import {ZaiStablecoin} from "../../contracts/core/ZaiStablecoin.sol";
import {DDHub, IDDHub} from "../../contracts/core/direct-deposit/DDHub.sol";
import {DDOperatorPlan, IDDPlan} from "../../contracts/core/direct-deposit/plans/DDOperatorPlan.sol";
import {DDMetaMorpho, IDDPool} from "../../contracts/core/direct-deposit/pools/DDMetaMorpho.sol";

import {BaseMorphoTest} from "./base/BaseMorphoTest.t.sol";

// todo test multiple hubs

contract DDHubTest is BaseMorphoTest {
  DDHub hub;
  DDMetaMorpho pool;
  DDOperatorPlan plan;

  address executor = makeAddr("executor");

  function setUp() public {
    _setUpMorpho();

    hub = new DDHub();

    hub.initialize(
      feeDestination, // address _feeCollector,
      100_000 ether, // uint256 _globalDebtCeiling,
      address(zai), // address _zai,
      governance // address _governance
    );

    plan = new DDOperatorPlan(0, governance);
    pool = new DDMetaMorpho();
    pool.initialize(address(hub), address(zai), address(vault));

    vm.label(address(hub), "DDHub");
    vm.label(address(pool), "DDOperatorPlan");
    vm.label(address(plan), "DDMetaMorpho");

    zai.grantManagerRole(address(hub));

    bytes32 executorRole = hub.EXECUTOR_ROLE();
    bytes32 opeartorRole = plan.OPERATOR_ROLE();

    vm.prank(governance);
    hub.grantRole(executorRole, executor);

    vm.prank(governance);
    plan.grantRole(opeartorRole, governance);
  }

  function _setupPool() internal {
    vm.prank(governance);
    hub.registerPool(pool, plan, 1000 ether);

    vm.prank(governance);
    plan.setTargetAssets(900 ether);
  }

  function test_values() public view {
    assertEq(address(hub.zai()), address(zai), "!zai");
    assertEq(hub.feeCollector(), feeDestination, "!feeDestination");
  }

  function test_registerPool() public {
    assertEq(hub.isPool(address(pool)), false);
    _setupPool();
    assertEq(hub.isPool(address(pool)), true);

    IDDHub.PoolInfo memory poolInfo = hub.poolInfos(pool);
    assertEq(address(poolInfo.plan), address(plan), "!plan");
    assertEq(poolInfo.debtCeiling, 1000 ether, "!debtCeiling");
    assertEq(poolInfo.isLive, true, "!isLive");
    assertEq(poolInfo.debt, 0, "!totalDebt");
  }

  function test_shouldMintZaiToPlanDebtLimit() public {
    _setupPool();

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 900 ether);
  }
}
