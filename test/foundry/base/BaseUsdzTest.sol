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

import {IERC20, MockERC20} from "../../../contracts/mocks/MockERC20.sol";
import {ERC4626Mock} from "../../../contracts/mocks/MockERC4626.sol";

abstract contract BaseUsdzTest is Test {
  event Transfer(address indexed from, address indexed to, uint256 value);

  ZaiStablecoin public usdz;
  MockERC20 public usdc;
  ERC4626Mock public sUsdc;

  address governance = makeAddr("governance");
  address feeDistributor = makeAddr("feeDistributor");

  function _setUpBase() internal {
    usdz = new ZaiStablecoin(address(this));
    usdc = new MockERC20("USD Coin", "USDC", 6);
    sUsdc = new ERC4626Mock(address(usdc));

    vm.label(address(usdz), "usdz");
    vm.label(address(usdc), "usdc");
    vm.label(address(sUsdc), "sUsdc");

    usdz.grantManagerRole(address(this));
    usdz.grantManagerRole(governance);
  }
}
