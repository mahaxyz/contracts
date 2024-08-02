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

pragma solidity 0.8.20;

import {BaseTest} from "./BaseTest.t.sol";

contract ZaiStablecoinTest is BaseTest {
  function setUp() public {
    setUpBase();
    zai.grantManagerRole(user);
  }

  function test_NameAndSymbol() public view {
    assertEq(zai.name(), "Zai Stablecoin");
    assertEq(zai.symbol(), "USDz");
  }

  function testGrantAndRevokeManagerRole() public {
    zai.grantManagerRole(user);
    assertTrue(zai.hasRole(zai.MANAGER_ROLE(), user));
    zai.revokeManagerRole(user);
    assertFalse(zai.hasRole(zai.MANAGER_ROLE(), user));
  }

  function testMintAndBurn() public {
    address minterBurner = address(0x7);
    vm.prank(user);
    zai.mint(minterBurner, 1000 * 1e18);
    assertEq(zai.balanceOf(minterBurner), 1000 * 1e18);

    vm.prank(user);
    zai.burn(minterBurner, 500 * 1e18);
    assertEq(zai.balanceOf(minterBurner), 500 * 1e18);

    vm.stopPrank();
  }

  function testMintAndBurnFailWithoutRole() public {
    vm.startPrank(ant);
    vm.expectRevert();
    zai.mint(user, 1000 * 1e18);

    vm.expectRevert();
    zai.burn(user, 500 * 1e18);
    vm.stopPrank();
  }

  function testIsManager() public {
    assertTrue(zai.isManager(user));
    assertFalse(zai.isManager(ant));
  }
}
