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

contract DDHubTest is BaseMorphoTest {
  DDHub public hub;
  DDMetaMorpho public samplePool;
  IDDPlan public samplePlan;

  function setUp() public {
    setUpMorpho();

    hub = new DDHub();

    hub.initialize(
      feeDestination, // address _feeCollector,
      100_000 ether, // uint256 _globalDebtCeiling,
      address(zai), // address _zai,
      governance // address _governance
    );

    samplePlan = new DDOperatorPlan(0, governance);
    samplePool = new DDMetaMorpho();
    samplePool.initialize(address(hub), address(zai), address(vault));

    zai.grantManagerRole(address(hub));
  }

  function test_values() public {
    assertEq(address(hub.zai()), address(zai), "!zai");
    assertEq(hub.feeCollector(), feeDestination, "!feeDestination");
  }

  function test_registerPool() public {
    assertEq(hub.isPool(address(samplePool)), false);

    vm.prank(governance);
    hub.registerPool(samplePool, samplePlan, 1000 ether);

    assertEq(hub.isPool(address(samplePool)), true);

    IDDHub.PoolInfo memory poolInfo = hub.poolInfos(samplePool);
    assertEq(address(poolInfo.plan), address(samplePlan), "!plan");
    assertEq(poolInfo.debtCeiling, 1000 ether, "!debtCeiling");
    assertEq(poolInfo.isLive, true, "!isLive");
    assertEq(poolInfo.debt, 0, "!totalDebt");
  }
}
