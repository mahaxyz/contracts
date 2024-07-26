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

import "./base/BaseDDHubTest.sol";

contract DDHubTestFees is BaseDDHubTest {
  function setUp() public {
    _setUpHub();
    _setupPool();

    // fund metamorpho with 900 zai
    vm.prank(governance);
    plan.setTargetAssets(900 ether);
    vm.prank(executor);
    hub.exec(pool);
  }

  function test_setFeeCollector() public {
    vm.prank(governance);
    hub.setFeeCollector(address(0x2));
    assertEq(hub.feeCollector(), address(0x2));
  }

  function test_sweepFeesWithMetaMorpho() public {
    // go forward 100 days to accure some interest
    vm.warp(block.timestamp + 100 days);

    assertEq(zai.balanceOf(feeDestination), 0);

    hub.sweepFees(pool);

    // roughly 132 zai would be the interest accured
    assertGe(zai.balanceOf(feeDestination), 100 ether);
  }
}
