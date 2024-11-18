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

import {PegStabilityModuleYield} from "../../../contracts/core/psm/PegStabilityModuleYield.sol";
import {BaseUsdzTest} from "./BaseUsdzTest.sol";

contract BasePsmYieldTest is BaseUsdzTest {
  PegStabilityModuleYield internal psmUSDe;

  function _setUpPSMYield() internal {
    _setUpBase();

    psmUSDe = new PegStabilityModuleYield();

    psmUSDe.initialize(
      address(usdz),
      address(sUsdc),
      governance,
      100_000 * 1e6, // supplyCap
      100_000 * 1e18, // debtCap
      100, // supplyFeeBps
      100, // redeemFeeBps
      feeDistributor // DistributorContract Address
    );

    usdz.grantManagerRole(address(psmUSDe));
  }
}
