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
import {Test, console} from "../../../lib/forge-std/src/Test.sol";

import {MockERC20} from "../../../contracts/mocks/MockERC20.sol";

abstract contract BaseZaiTest is Test {
  event Transfer(address indexed from, address indexed to, uint256 value);

  ZaiStablecoin public zai;

  MockERC20 public usdc;
  MockERC20 public maha;
  MockERC20 public dai;
  MockERC20 public weth;

  address governance = makeAddr("governance");
  address shark = makeAddr("shark");
  address whale = makeAddr("whale");
  address ant = makeAddr("ant");
  address feeDestination = makeAddr("feeDestination");

  function _setUpBase() internal {
    zai = new ZaiStablecoin(address(this));

    usdc = new MockERC20("USD Coin", "USDC", 8);
    dai = new MockERC20("DAI", "DAI", 18);
    maha = new MockERC20("MahaDAO", "MAHA", 18);
    weth = new MockERC20("Wrapped Ether", "WETH", 18);

    vm.label(address(zai), "zai");
    vm.label(address(usdc), "usdc");
    vm.label(address(dai), "dai");
    vm.label(address(weth), "weth");

    zai.grantManagerRole(address(this));
    zai.grantManagerRole(governance);
  }
}
