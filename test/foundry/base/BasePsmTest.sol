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

import {PegStabilityModule} from "../../../contracts/core/psm/PegStabilityModule.sol";
import "./BaseZaiTest.sol";

contract BasePsmTest is BaseZaiTest {
  PegStabilityModule internal psmUSDC;
  PegStabilityModule internal psmDAI;

  function _setUpPSM() internal {
    _setUpBase();

    psmUSDC = new PegStabilityModule();
    psmUSDC.initialize(
      address(zai), // address _zai,
      address(usdc), // address _collateral,
      governance, // address _governance,
      1e6, // uint256 _newRate,
      100_000 * 1e6, // uint256 _supplyCap,
      100_000 * 1e18, // uint256 _debtCap
      100, // supplyFeeBps 1%
      100, // redeemFeeBps 1%
      feeDestination
    );

    psmDAI = new PegStabilityModule();
    psmDAI.initialize(
      address(zai), // address _zai,
      address(dai), // address _collateral,
      governance, // address _governance,
      1e18, // uint256 _newRate,
      100_000 * 1e18, // uint256 _supplyCap,
      100_000 * 1e18, // uint256 _debtCap
      100, // supplyFeeBps 1%
      100, // redeemFeeBps 1%
      feeDestination
    );

    // give permissions
    zai.grantManagerRole(address(psmUSDC));
    zai.grantManagerRole(address(psmDAI));
  }
}
