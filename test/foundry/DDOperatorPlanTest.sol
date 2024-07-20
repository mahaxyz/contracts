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

import "../../contracts/core/direct-deposit/plans/DDOperatorPlan.sol";
import {BaseZaiTest} from "./base/BaseZaiTest.sol";

contract DDOperatorPlanTest is BaseZaiTest {
  DDOperatorPlan private plan;

  function setUp() public {
    _setUpBase();
    plan = new DDOperatorPlan(0, governance);

    assertEq(plan.active(), true);
    assertEq(plan.enabled(), 1);
  }

  function test_planDisable() public {
    assertEq(plan.active(), true);

    vm.prank(governance);
    plan.disable();

    assertEq(plan.active(), false);
    assertEq(plan.enabled(), 0);
  }
}
