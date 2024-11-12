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

import {BasePsmYieldTest} from  "./base/BasePsmYieldTest.sol";
import {console} from "hardhat/console.sol";

contract PegStabilityModuleYieldTest is BasePsmYieldTest {

    function setUp() public {
        _setUpPSMYield();
    }

    function test_values() public view {
    // assertEq(address(psmUSDe), address(usdz), "!psm");
    assertEq(psmUSDe.supplyCap(), 100_000 * 1e6, "!supplyCap");
    assertEq(psmUSDe.debtCap(), 100_000 ether, "!debtCap");
    assertEq(psmUSDe.debt(), 0, "!debt");
  }
}



