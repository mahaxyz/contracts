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

import {SafetyPool, SafetyPoolEvents} from "../../contracts/core/safety-pool/SafetyPool.sol";
import {BaseZaiTest, console} from "./base/BaseZaiTest.sol";

contract SafetyPoolTest is BaseZaiTest {
  SafetyPool internal safetyPool;

  function setUp() public {
    _setUpBase();
    zai.mint(whale, 1000 ether);

    safetyPool = new SafetyPool();
    safetyPool.initialize(
      "Safety Pool", "sZAI", address(zai), 10 days, governance, address(usdc), address(maha), 7 days
    );

    vm.prank(whale);
    zai.approve(address(safetyPool), type(uint256).max);
  }

  function test_deposit() public {
    vm.prank(whale);
    safetyPool.deposit(100 ether, whale);
  }

  function test_withdrawal() public {
    vm.startPrank(whale);
    safetyPool.deposit(100 ether, whale);

    vm.expectRevert(bytes("invalid withdrawal"));
    safetyPool.withdraw(100 ether, ant, whale);

    safetyPool.queueWithdrawal(100 ether);

    vm.expectRevert(bytes("withdrawal not ready"));
    safetyPool.withdraw(100 ether, ant, whale);

    vm.warp(block.timestamp + 10 days + 1);

    vm.expectRevert(bytes("invalid withdrawal"));
    safetyPool.withdraw(10 ether, ant, whale);

    vm.expectEmit(address(safetyPool));
    emit SafetyPoolEvents.WithdrawalQueueUpdated(0, 0, whale);
    safetyPool.withdraw(100 ether, ant, whale);

    assertEq(100 ether, zai.balanceOf(ant));
    assertEq(900 ether, zai.balanceOf(whale));
    assertEq(0, zai.balanceOf(address(safetyPool)));

    vm.stopPrank();
  }

  function test_slashing() public {
    vm.startPrank(whale);
    safetyPool.deposit(100 ether, whale);

    vm.expectRevert(bytes("invalid withdrawal"));
    safetyPool.withdraw(100 ether, ant, whale);

    safetyPool.queueWithdrawal(100 ether);

    vm.expectRevert(bytes("withdrawal not ready"));
    safetyPool.withdraw(100 ether, ant, whale);

    vm.warp(block.timestamp + 10 days + 1);

    vm.expectRevert(bytes("invalid withdrawal"));
    safetyPool.withdraw(10 ether, ant, whale);

    vm.expectEmit(address(safetyPool));
    emit SafetyPoolEvents.WithdrawalQueueUpdated(0, 0, whale);
    safetyPool.withdraw(100 ether, ant, whale);

    assertEq(100 ether, zai.balanceOf(ant));
    assertEq(900 ether, zai.balanceOf(whale));
    assertEq(0, zai.balanceOf(address(safetyPool)));

    vm.stopPrank();
  }
}
