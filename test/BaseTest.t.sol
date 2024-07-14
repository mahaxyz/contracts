// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZaiStablecoin} from '../contracts/core/ZaiStablecoin.sol';
import {MockLayerZero} from '../contracts/tests/MockLayerZero.sol';
import {Test, console} from '../lib/forge-std/src/Test.sol';

import {PegStabilityModule} from '../contracts/core/PegStabilityModule.sol';
import {MockERC20} from '../contracts/tests/MockERC20.sol';

abstract contract BaseTest is Test {
  ZaiStablecoin public zai;

  PegStabilityModule public psmUSDC;
  PegStabilityModule public psmDAI;

  MockERC20 public usdc;
  MockERC20 public dai;
  MockERC20 public weth;

  address governance = address(0x1);
  address shark = address(0x2);
  address whale = address(0x3);
  address ant = address(0x4);

  function setUpBase() internal {
    MockLayerZero lz = new MockLayerZero();
    zai = new ZaiStablecoin(address(lz), address(0x1));

    usdc = new MockERC20('USD Coin', 'USDC', 8);
    dai = new MockERC20('DAI', 'DAI', 18);
    weth = new MockERC20('Wrapped Ether', 'WETH', 18);

    psmUSDC = new PegStabilityModule(
      address(zai), // address _zai,
      address(usdc), // address _collateral,
      governance, // address _governance,
      1e8, // uint256 _newRate,
      100_000 * 1e8, // uint256 _supplyCap,
      100_000 * 1e18 // uint256 _debtCap
    );

    psmDAI = new PegStabilityModule(
      address(zai), // address _zai,
      address(dai), // address _collateral,
      governance, // address _governance,
      1e18, // uint256 _newRate,
      100_000 * 1e18, // uint256 _supplyCap,
      100_000 * 1e18 // uint256 _debtCap
    );

    // give permissions
    zai.grantManagerRole(address(psmUSDC));
    zai.grantManagerRole(address(psmDAI));
  }
}
