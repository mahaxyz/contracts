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

contract DDHubTestShutdown is BaseDDHubTest {
  function setUp() public {
    _setUpHub();
    _setupPool();

    // fund metamorpho with 1000 zai
    vm.prank(executor);
    hub.exec(pool);
  }

  function test_shutdownViaPlanDisabled() public {
    vm.prank(governance);
    plan.disable();

    vm.expectEmit(address(hub));
    emit DDEventsLib.BurnDebt(pool, 1000 ether - 1);

    vm.prank(executor);
    hub.exec(pool);
  }

  function test_shutdownViaShutdownPoolCall() public {
    vm.prank(riskManager);
    hub.shutdownPool(pool);

    vm.expectEmit(address(hub));
    emit DDEventsLib.BurnDebt(pool, 1000 ether - 1);

    vm.prank(executor);
    hub.exec(pool);
  }
}
