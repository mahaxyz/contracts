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

contract DDHubTestSimple is BaseDDHubTest {
  function setUp() public {
    _setUpHub();
    _setupPool();
  }

  function test_reduceDebtCeiling() public {
    IDDHub.PoolInfo memory poolInfo = hub.poolInfos(pool);
    assertEq(poolInfo.debtCeiling, 1000 ether);

    vm.prank(riskManager);
    hub.reduceDebtCeiling(pool, 300 ether);

    poolInfo = hub.poolInfos(pool);
    assertEq(poolInfo.debtCeiling, 700 ether);
  }

  function test_shutdownPool() public {
    IDDHub.PoolInfo memory poolInfo = hub.poolInfos(pool);
    assertEq(poolInfo.isLive, true);

    vm.prank(riskManager);
    hub.shutdownPool(pool);

    poolInfo = hub.poolInfos(pool);
    assertEq(poolInfo.isLive, false);
  }
}
