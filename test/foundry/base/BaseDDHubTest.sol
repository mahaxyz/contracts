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

import {ZaiStablecoin} from "../../../contracts/core/ZaiStablecoin.sol";
import {DDEventsLib, IDDHub} from "../../../contracts/core/direct-deposit/hub/DDHubBase.sol";
import {DDHubL1} from "../../../contracts/core/direct-deposit/hub/DDHubL1.sol";
import {DDOperatorPlan, IDDPlan} from "../../../contracts/core/direct-deposit/plans/DDOperatorPlan.sol";
import {DDMetaMorpho, IDDPool} from "../../../contracts/core/direct-deposit/pools/DDMetaMorpho.sol";

import {BaseMorphoTest} from "./BaseMorphoTest.sol";

// todo test multiple pools
// todo test multiple hubs

abstract contract BaseDDHubTest is BaseMorphoTest {
  DDHubL1 internal hub;
  DDMetaMorpho internal pool;
  DDOperatorPlan internal plan;

  address internal executor = makeAddr("executor");
  address internal riskManager = makeAddr("riskManager");

  function _setUpHub() public {
    _setUpMorpho();

    hub = new DDHubL1();

    hub.initialize(
      feeDestination, // address _feeCollector,
      100_000 ether, // uint256 _globalDebtCeiling,
      address(zai), // address _zai,
      governance // address _governance
    );

    plan = new DDOperatorPlan(0, governance, 0);
    pool = new DDMetaMorpho();
    pool.initialize(address(hub), address(zai), address(vault));

    zai.grantManagerRole(address(hub));

    bytes32 executorRole = hub.EXECUTOR_ROLE();
    bytes32 riskRole = hub.RISK_ROLE();
    bytes32 opeartorRole = plan.OPERATOR_ROLE();

    vm.prank(governance);
    hub.grantRole(executorRole, executor);

    vm.prank(governance);
    plan.grantRole(opeartorRole, governance);

    vm.prank(governance);
    hub.grantRole(riskRole, riskManager);

    vm.label(address(hub), "DDHub");
    vm.label(address(pool), "DDOperatorPlan");
    vm.label(address(plan), "DDMetaMorpho");
  }

  function _setupPool() internal {
    vm.prank(governance);
    hub.registerPool(pool, plan, 1000 ether);

    vm.prank(governance);
    plan.setTargetAssets(1000 ether);
  }
}
