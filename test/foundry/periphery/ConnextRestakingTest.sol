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

import {MockConnext} from "../../../contracts/mocks/MockConnext.sol";

import {XERC20} from "../../../contracts/periphery/restaking/XERC20.sol";
import {XERC20Lockbox} from "../../../contracts/periphery/restaking/XERC20Lockbox.sol";
import {L1BridgeCollateralConnext} from "../../../contracts/periphery/restaking/connext/L1BridgeCollateralConnext.sol";
import {L2DepositCollateralConnext} from "../../../contracts/periphery/restaking/connext/L2DepositCollateralConnext.sol";
import "../base/BasePsmTest.sol";

contract ConnextRestakingTest is BasePsmTest {
  MockConnext bridge;

  XERC20 localZAI;
  XERC20Lockbox lockbox;

  XERC20 remoteZAI;
  MockERC20 remoteUSDC;
  MockERC20 remoteUSDCx;

  L1BridgeCollateralConnext l1Bridge;
  L2DepositCollateralConnext l2Bridge;

  function setUp() external {
    _setUpPSM();

    bridge = new MockConnext();

    localZAI = new XERC20();
    remoteZAI = new XERC20();
    remoteUSDC = new MockERC20("USDC", "USDC", 6);
    remoteUSDCx = new MockERC20("xUSDC", "xUSDC", 6);
    lockbox = new XERC20Lockbox();
    l1Bridge = new L1BridgeCollateralConnext();
    l2Bridge = new L2DepositCollateralConnext();

    localZAI.initialize("ZAI", "xZAI", address(this));
    remoteZAI.initialize("ZAI", "xZAI", address(this));
    lockbox.initialize(address(localZAI), address(zai), false);

    l1Bridge.initialize(
      zai, // IERC20 _zai,
      localZAI, // IERC20 _xZai,
      psmUSDC, // IPegStabilityModule _psm,
      usdc, // IERC20 _collateral,
      lockbox, // IXERC20Lockbox _lockbox,
      address(bridge) // address _connext
    );

    l2Bridge.initialize(
      remoteZAI, // IERC20 _xZAI,
      remoteUSDC, // IERC20 _depositToken,
      remoteUSDCx, // IERC20 _collateralToken,
      bridge, // IConnext _connext,
      "0x", // bytes32 _swapKey,
      100, // uint32 _bridgeDestinationDomain,
      address(l1Bridge), // address _bridgeTargetAddress,
      address(this), // address _owner,
      1e6, // uint256 _rate
      1e6 // uint256 _sweepBatchSize
    );

    l2Bridge.setAllowedBridgeSweeper(address(this), true);

    // give limits
    localZAI.setLimits(address(l1Bridge), 0, 1e18 * 10_000_000);
    localZAI.setLockbox(address(lockbox));
    remoteZAI.setLimits(address(l2Bridge), 1e18 * 10_000_000, 0);

    bridge.setBridgeMapping(address(remoteUSDCx), address(usdc));
  }

  function test_l1Bridge() external {
    usdc.mint(address(l1Bridge), 100e6);
    vm.prank(address(bridge));
    l1Bridge.xReceive(
      bytes32(0), // bytes32 _transferId,
      100e6, // uint256 _amount,
      address(usdc), // address _asset,
      address(0x1), // address _originSender,
      1, // uint32 _origin,
      "" // bytes memory
    );
  }

  function test_l2Bridge() public {
    vm.startPrank(whale);
    assertEq(remoteZAI.balanceOf(whale), 0);

    remoteUSDC.mint(address(whale), 100e6);
    remoteUSDC.approve(address(l2Bridge), 100e6);
    l2Bridge.deposit(100e6, 0, block.timestamp + 1000);
    vm.stopPrank();

    assertApproxEqAbs(remoteZAI.balanceOf(whale), 100e18, 1e17);
  }

  function test_fullConnextLoop() external {
    test_l2Bridge(); // deposit

    l2Bridge.sweep(); // sweep and hit the l1Bridge
  }
}
