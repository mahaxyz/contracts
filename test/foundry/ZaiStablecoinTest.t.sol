// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ZaiStablecoin} from '../../contracts/core/ZaiStablecoin.sol';
import {MockLayerZero} from '../../contracts/tests/MockLayerZero.sol';
import {Test, console} from '../../lib/forge-std/src/Test.sol';

contract ZaiStablecoinTest is Test {
  ZaiStablecoin public zai;

  function setUp() public {
    MockLayerZero lz = new MockLayerZero();
    zai = new ZaiStablecoin(address(lz), address(0x1));
  }

  function test_NameAndSymbol() public view {
    assertEq(zai.name(), 'Zai Stablecoin');
    assertEq(zai.symbol(), 'USDz');
  }
}
