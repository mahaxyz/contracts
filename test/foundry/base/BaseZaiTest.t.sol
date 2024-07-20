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

import {ZaiStablecoin} from "../../../contracts/core/ZaiStablecoin.sol";
import {MockLayerZero} from "../../../contracts/tests/MockLayerZero.sol";
import {Test, console} from "../../../lib/forge-std/src/Test.sol";

import {MockERC20} from "../../../contracts/tests/MockERC20.sol";

abstract contract BaseZaiTest is Test {
  ZaiStablecoin public zai;

  MockERC20 public usdc;
  MockERC20 public dai;
  MockERC20 public weth;

  address governance = makeAddr("governance");
  address shark = makeAddr("shark");
  address whale = makeAddr("whale");
  address ant = makeAddr("ant");
  address feeDestination = makeAddr("feeDestination");

  function setUpBase() internal {
    MockLayerZero lz = new MockLayerZero();
    zai = new ZaiStablecoin(address(lz), address(0x1));

    usdc = new MockERC20("USD Coin", "USDC", 8);
    dai = new MockERC20("DAI", "DAI", 18);
    weth = new MockERC20("Wrapped Ether", "WETH", 18);

    zai.grantManagerRole(address(this));
  }
}
