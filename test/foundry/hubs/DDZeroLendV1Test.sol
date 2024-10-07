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

import {IDDPool} from "../../../contracts/core/direct-deposit/hub/DDHubBase.sol";
import {DDHubL1} from "../../../contracts/core/direct-deposit/hub/DDHubL1.sol";
import {DDOperatorPlan} from "../../../contracts/core/direct-deposit/plans/DDOperatorPlan.sol";
import {DDZeroLendV1} from "../../../contracts/core/direct-deposit/pools/DDZeroLendV1.sol";

import {IERC20, MockCurvePool} from "../../../contracts/mocks/MockCurvePool.sol";
import {ZapAerodromePoolUSDC} from "../../../contracts/periphery/zaps/implementations/base/ZapAerodromePoolUSDC.sol";
import {BaseZaiTest, console} from "../base/BaseZaiTest.sol";

contract DDZeroLendV1Test is BaseZaiTest {
  string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");

  function test_dd_zerolend_pool_fork() public {
    uint256 mainnetFork = vm.createFork(MAINNET_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(20_875_705);

    address timelock = 0x690002dA1F2d828D72Aa89367623dF7A432E85A9;
    address deployer = 0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b;
    address safe = 0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC;

    IERC20 _zai = IERC20(0x69000405f9DcE69BD4Cbf4f2865b79144A69BFE0);
    address _z0pool = 0xD3a4DA66EC15a001466F324FA08037f3272BDbE8;
    IERC20 _z0USDz = IERC20(0xC79b0AF546577Fd71C14641473451836Abb6f109);

    DDHubL1 hub = DDHubL1(0x51a021e3B7874d451347a56152C47136593b6740);

    // create the pool
    DDZeroLendV1 dd = new DDZeroLendV1();
    dd.initialize(address(hub), address(_zai), address(_z0pool), address(_z0USDz));

    // create the plan
    DDOperatorPlan plan = new DDOperatorPlan(0, safe, 1000e18);

    // register the pool
    vm.prank(timelock);
    hub.registerPool(dd, plan, 1000e18);

    // supply into zerolend
    vm.prank(deployer);
    hub.exec(dd);

    assertEq(_z0USDz.balanceOf(address(dd)), 1000e18, "!z0USDz.balanceOf(dd)");
    assertGe(_zai.balanceOf(address(_z0USDz)), 1000e18, "!zai.balanceOf(z0USDz)");
  }
}
