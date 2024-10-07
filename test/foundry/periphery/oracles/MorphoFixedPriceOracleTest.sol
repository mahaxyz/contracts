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

import {MorphoFixedPriceOracle} from "../../../../contracts/periphery/oracles/MorphoFixedPriceOracle.sol";
import {
  AggregatorV3Interface,
  IERC4626,
  MorphoChainlinkOracleV2
} from "../../../../lib/morpho-blue-oracles/src/morpho-chainlink/MorphoChainlinkOracleV2.sol";
import {BaseZaiTest, IERC20, console} from "../../base/BaseZaiTest.sol";

contract MorphoFixedPriceOracleTest is BaseZaiTest {
  string BASE_RPC_URL = vm.envString("BASE_RPC_URL");

  function setUp() public {
    uint256 baseFork = vm.createFork(BASE_RPC_URL);
    vm.selectFork(baseFork);
    vm.rollFork(19_141_574);
  }

  function test_oracle_lp() public {
    MorphoFixedPriceOracle oracle = new MorphoFixedPriceOracle(2e24, 18);

    assertApproxEqAbs(oracle.getPriceFor(29_999_999_999_998_000), 60_000 ether, 1e10, "!oracle.getPriceFor");
    assertEq(oracle.price() / 1e36, 2_000_000, "!morphoOracle.price");
  }
}
