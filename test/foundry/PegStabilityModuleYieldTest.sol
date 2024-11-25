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

import {BasePsmYieldTest} from "./base/BasePsmYieldTest.sol";
import {console} from "hardhat/console.sol";

import {IPegStabilityModule, PegStabilityModuleYield} from "../../contracts/core/psm/PegStabilityModuleYield.sol";
import {ITransparentUpgradeableProxy, ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract PegStabilityModuleYieldTest is BasePsmYieldTest {
  string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_upgrade() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(21_266_235);

    address upgradedImpl = address(new PegStabilityModuleYield());
    PegStabilityModuleYield psm = PegStabilityModuleYield(0x27Bad7b0d3E1aF5e8940feBdDfC4fF0C128b58Eb);

    ProxyAdmin proxyAdmin = ProxyAdmin(0x6900064e7A3920C114E25B5FE4780F26520E3231);

    vm.prank(address(proxyAdmin));
    ITransparentUpgradeableProxy(address(psm)).upgradeToAndCall(upgradedImpl, "");

    psm.initialize(
      0x69000dFD5025E82f48Eb28325A2B88a241182CEd,
      0x9D39A5DE30e57443BfF2A8307A4256c8797A3497,
      governance,
      100_000 * 1e6, // supplyCap
      100_000 * 1e18, // debtCap
      0, // supplyFeeBps
      100, // redeemFeeBps
      feeDistributor // DistributorContract Address
    );
  }
}
