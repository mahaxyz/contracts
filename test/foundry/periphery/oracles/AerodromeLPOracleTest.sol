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

import {AerodromeLPOracle, IAerodromePool} from "../../../../contracts/periphery/oracles/AerodromeLPOracle.sol";
import {FixedPriceOracle} from "../../../../contracts/periphery/oracles/FixedPriceOracle.sol";
import {BaseZaiTest, IERC20, console} from "../../base/BaseZaiTest.sol";

contract AerodromeLPOracleTest is BaseZaiTest {
  IAerodromePool public pool;

  string BASE_RPC_URL = vm.envString("BASE_RPC_URL");

  function test_zap_fork() public {
    uint256 mainnetFork = vm.createFork(BASE_RPC_URL);
    vm.selectFork(mainnetFork);
    vm.rollFork(19_141_574);

    pool = IAerodromePool(0x72d509aFF75753aAaD6A10d3EB98f2DBC58C480D);

    FixedPriceOracle fixedOracle = new FixedPriceOracle(1e8, 8);

    AerodromeLPOracle oracle = new AerodromeLPOracle(address(fixedOracle), address(fixedOracle), address(pool));

    // assertGe(_pool.balanceOf(address(_staking)), 0, "!pool.balanceOf(staking)");
    // assertEq(oracle.getPriceFor(29_999_999_999_998_000), 50_000, "!oracle.getPriceFor");

    // assertEq(_zai.balanceOf(address(_zap)), 0, "!zai.balanceOf(zap)");
    // assertEq(_usdc.balanceOf(address(_zap)), 0, "!usdc.balanceOf(zap)");

    // assertApproxEqAbs(_staking.balanceOf(user), 100e18, 1e18, "!staking.balanceOf(user)");
  }
}
