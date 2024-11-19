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

import {SafetyPool} from "../../contracts/core/safety-pool/SafetyPool.sol";
import {SUSDECollectorCron} from "../../contracts/periphery/crons/sUSDeCollectorCron.sol";
import {PegStabilityModuleYieldFork} from "./PegStabilityModuleFork.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import "forge-std/console.sol";

contract SUSDEForkTest is PegStabilityModuleYieldFork {
  SUSDECollectorCron public collector;
  IERC20 public _usdc;
  SafetyPool public _sUSDz;

  // Data Generated from Odos API for sUSDe to USDC 
  bytes odosCalldata =
    hex"83bd37f900019d39a5de30e57443bff2a8307a4256c8797a34970001a0b86991c6218b36c1d19d4a2e9eb0ce3606eb4807038d7ea4c6800002046000c49b0001B28Ca7e465C452cE4252598e0Bc96Aeba553CF82000000012e234DAe75C793f67A35089C9d99245E1C58470b0000000004020203000701010102b819feef8f0fcdc268afe14162983a69f6bf179e000000000000000000000689ff000000000000000000000000000000000000000000009d39a5de30e57443bff2a8307a4256c8797a3497a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000000000000000000000000000";

  function setUp() public override {
    _setUpPSMY();

    collector = new SUSDECollectorCron();
    _usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    _sUSDz = SafetyPool(0x69000E468f7f6d6f4ed00cF46f368ACDAc252553);

    collector.initialize(
      address(0xCf5540fFFCdC3d510B18bFcA6d2b9987b0772559), address(_sUSDz), address(_usdc), address(sUSDe)
    );

    vm.startPrank(GOVERNANCE);
    psm.updateFeeDistributor(address(collector));
    vm.stopPrank();
    console.log("Collector Address", address(collector));
  }

  function testInitValuesCollector() external view {
    assertEq(collector.sUSDz(), address(_sUSDz));
    assertEq(address(collector.usdc()), address(_usdc));
  }

  function testSwapOdosUSDC() external {
    uint256 usdcBalanceBefore = IERC20(address(_usdc)).balanceOf(address(collector));
    console.log("Before Collector USDC Balance", usdcBalanceBefore);
    testTransferYieldToFeeDistributor();
    uint256 amount = 0.001 ether;
    collector.swapToUSDC(odosCalldata, amount);
    uint256 usdcBalanceAfter = IERC20(address(_usdc)).balanceOf(address(collector));
    console.log("After Collector USDC Balance", usdcBalanceAfter);
    assertGt(usdcBalanceAfter,usdcBalanceBefore,"USDC After > USDC Before");
    vm.stopPrank();
  }
}
