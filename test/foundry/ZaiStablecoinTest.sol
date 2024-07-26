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

import {BaseZaiTest} from "./base/BaseZaiTest.sol";

contract ZaiStablecoinTest is BaseZaiTest {
  function setUp() public {
    _setUpBase();

    zai.grantManagerRole(whale);
  }

  function test_nameAndSymbol() public view {
    assertEq(zai.name(), "ZAI Stablecoin");
    assertEq(zai.symbol(), "USDz");
  }

  function test_isManager() public view {
    assertEq(zai.isManager(governance), true);
    assertEq(zai.isManager(address(0x69)), false);
  }

  function test_revokeManager() public {
    assertEq(zai.isManager(governance), true);
    assertEq(zai.isManager(address(this)), true);

    zai.revokeManagerRole(address(this));

    assertEq(zai.isManager(governance), true);
    assertEq(zai.isManager(address(this)), false);

    vm.expectRevert();
    vm.prank(governance);
    zai.revokeManagerRole(governance);

    zai.revokeManagerRole(governance);

    assertEq(zai.isManager(governance), false);
    assertEq(zai.isManager(address(this)), false);
  }
}
