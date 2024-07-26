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

    bytes32 role = safetyPool.MANAGER_ROLE();
    vm.prank(governance);
    safetyPool.grantRole(role, governance);

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

  function test_coverBadDebt() public {
    vm.prank(whale);
    safetyPool.mint(100 ether, whale);

    vm.prank(governance);
    safetyPool.coverBadDebt(1 ether);
    assertEq(1 ether, zai.balanceOf(governance)); // 1 zai
    assertEq(99 ether, zai.balanceOf(address(safetyPool))); // 99 zai

    vm.startPrank(whale);

    // user should be slashed by 1%

    safetyPool.queueWithdrawal(10 ether);
    vm.warp(block.timestamp + 10 days + 1);
    safetyPool.redeem(10 ether, ant, whale);

    assertEq(99 ether / 10, zai.balanceOf(ant)); // 9.9 zai
    assertEq(900 ether, zai.balanceOf(whale)); // 900 zai
    assertEq(891 ether / 10, zai.balanceOf(address(safetyPool))); // 89.1 zai

    vm.stopPrank();
  }

  function test_cancelWithdrawal() public {
    vm.startPrank(whale);
    safetyPool.deposit(100 ether, whale);

    safetyPool.queueWithdrawal(100 ether);

    vm.expectRevert(bytes("withdrawal not ready"));
    safetyPool.withdraw(100 ether, ant, whale);

    vm.warp(block.timestamp + 10 days + 1);

    vm.expectEmit(address(safetyPool));
    emit SafetyPoolEvents.WithdrawalQueueUpdated(0, 0, whale);
    safetyPool.cancelWithdrawal();

    vm.expectRevert(bytes("invalid withdrawal"));
    safetyPool.withdraw(100 ether, ant, whale);

    vm.stopPrank();
  }
}
