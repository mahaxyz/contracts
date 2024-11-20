// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.21;

import {ZapAerodromePoolUSDC} from "../../contracts/periphery/zaps/implementations/base/ZapAerodromePoolUSDC.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";

contract USDCZapForkTest is Test {
  ZapAerodromePoolUSDC public zapOdos;
  uint256 public baseMainnetForkId;
  string public BASE_RPC_URL = vm.envString("BASE_RPC_URL");
  address staking = 0x1097dFe9539350cb466dF9CA89A5e61195A520B0;
  address bridge = 0xA07cf1c081F46524A133c1B6E8eE0B5f96A51255;
  address odos = 0x19cEeAd7105607Cd444F5ad10dd51356436095a1;
  address router = 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43;

  function setUp() public {
    baseMainnetForkId = vm.createFork(BASE_RPC_URL);
    vm.selectFork(baseMainnetForkId);
    zapOdos = new ZapAerodromePoolUSDC(staking, bridge, router, address(odos));
  }

  function testInitValues() external view {
    assertEq(address(zapOdos.staking()), 0x1097dFe9539350cb466dF9CA89A5e61195A520B0);
    assertEq(address(zapOdos.zai()), 0x0A27E060C0406f8Ab7B64e3BEE036a37e5a62853);
    assertEq(address(zapOdos.router()), 0xcF77a3Ba9A5CA399B7c97c74d54e5b1Beb874E43);
    assertEq(zapOdos.odos(), 0x19cEeAd7105607Cd444F5ad10dd51356436095a1);
  }

  function testZapIntoLPOdosETH() external {
    vm.startPrank(0x1A9CE4fC65b2267bb32d692E17dE54Ff996747D8);
    IERC20 swapAsset = IERC20(address(0));
    vm.deal(0x1A9CE4fC65b2267bb32d692E17dE54Ff996747D8, 5 ether);
    uint256 swapAmount = 0.0001 ether;
    uint256 minLpAmount = 0;
    bytes memory odosCall =
      hex"83bd37f900000004065af3107a40000304c57b00c49b00017882570840A97A490a37bd8Db9e1aE39165bfBd6000000015615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f000000000301020300040101020a0001010201ff00000000000000000000000000000000001db0d0cb84914d09a92ba11d122bab732ac35fe04200000000000000000000000000000000000006000000000000000000000000000000000000000000000000";
    zapOdos.zapIntoLPWithOdos{value: swapAmount}(swapAsset, swapAmount, minLpAmount, odosCall);
    vm.stopPrank();
  }

  function testZapIntoODOSToken() external {
    address caller = 0x1A9CE4fC65b2267bb32d692E17dE54Ff996747D8;
    address ZRO = 0x6985884C4392D348587B19cb9eAAf157F13271cd;
    address ZRO_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    vm.startPrank(ZRO_WHALE);
    IERC20(ZRO).transfer(caller, 200 ether);
    vm.stopPrank();
    vm.startPrank(caller);
    IERC20(ZRO).approve(address(zapOdos), 100 ether);
    IERC20 swapAsset = IERC20(ZRO); // ZRO
    uint256 swapAmount = 100 ether;
    uint256 minLpAmount = 0;
    bytes memory odosCall =
      hex"83bd37f900016985884c4392d348587b19cb9eaaf157f13271cd000409056bc75e2d631000000414fa581400c49b00017882570840A97A490a37bd8Db9e1aE39165bfBd6000000015615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f000000000903030a013d2d88e4340100010102007fffffdd0160ee122c0a0100030200000a0100040200037b5bea170000020a0200050601040a010107080000260101090601ff000000000000000000000000000000000000000000000000000000000000deac3451b21038b89476ea60c8bb21bdfe97995e6985884c4392d348587b19cb9eaaf157f13271cd899cd88db60c1484ceebbf9b0a91a9a6415d485bcaeedd8f1acf55f2df259afc090d519069f72a2bbf371ea62f6464d092f715f6cd359bd22e24ff514200000000000000000000000000000000000006b94b22332abf5f89877a14cc88f2abc48c34b3dfcbb7c0000ab88b473b1f5afd9ef808440eed33bf4cfd5ba4b8e0475d9a3cfa863e0e18ccf9d3eb25000000000000000000000000";
    zapOdos.zapIntoLPWithOdos(swapAsset, swapAmount, minLpAmount, odosCall);
    vm.stopPrank();
  }
}
