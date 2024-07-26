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

  function test_shouldMintZaiToPlanTargetAssets() public {
    _setupPool();

    vm.prank(governance);
    plan.setTargetAssets(900 ether);

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 900 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 900 ether);
  }

  function test_shouldMintZaiToGlobalDebtLimit() public {
    _setupPool();

    vm.prank(governance);
    hub.setGlobalDebtCeiling(10 ether);

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 10 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 10 ether);
  }

  function test_shouldMintZaiToPoolDebtLimit() public {
    _setupPool();

    vm.prank(governance);
    hub.setDebtCeiling(pool, 100 ether);

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 100 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 100 ether);
  }

  function test_shouldRevertWithNoOp() public {
    _setupPool();

    vm.prank(governance);
    hub.setDebtCeiling(pool, 100 ether);

    vm.prank(executor);
    hub.exec(pool);

    vm.expectRevert();
    vm.prank(executor);
    hub.exec(pool);
  }

  function test_shouldWithdrawZaiAfterTargetAssetsReduced() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.prank(governance);
    plan.setTargetAssets(100 ether);

    // zai burn event
    vm.expectEmit(address(zai));
    emit Transfer(address(hub), address(0), 900 ether - 1);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 100 ether + 1);
  }

  function test_shouldWithdrawZaiAfterPoolDebtReduced() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.prank(governance);
    hub.setDebtCeiling(pool, 100 ether);

    // zai burn event
    vm.expectEmit(address(zai));
    emit Transfer(address(hub), address(0), 900 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 100 ether);
  }

  function test_shouldWithdrawZaiAfterGlobalDebtReduced() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.prank(governance);
    hub.setGlobalDebtCeiling(100 ether);

    // zai burn event
    vm.expectEmit(address(zai));
    emit Transfer(address(hub), address(0), 900 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 100 ether);
  }

  function test_showMintZaiAfterTargetAssetsIncreased() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.startPrank(governance);
    plan.setTargetAssets(1500 ether);
    hub.setGlobalDebtCeiling(2000 ether);
    hub.setDebtCeiling(pool, 2000 ether);
    vm.stopPrank();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 500 ether + 1);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1500 ether + 1);
  }

  function test_showMintZaiAfterPoolDebtIncreased() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.startPrank(governance);
    plan.setTargetAssets(2000 ether);
    hub.setGlobalDebtCeiling(2000 ether);
    hub.setDebtCeiling(pool, 1500 ether);
    vm.stopPrank();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 500 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1500 ether);
  }

  function test_showMintZaiAfterGlobalDebtIncreased() public {
    _setupPool();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 1000 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1000 ether);

    vm.startPrank(governance);
    plan.setTargetAssets(2000 ether);
    hub.setGlobalDebtCeiling(1500 ether);
    hub.setDebtCeiling(pool, 2000 ether);
    vm.stopPrank();

    // zai mint event
    vm.expectEmit(address(zai));
    emit Transfer(address(0), address(hub), 500 ether);

    vm.prank(executor);
    hub.exec(pool);

    assertEq(zai.balanceOf(address(morpho)), 1500 ether);
  }
}
