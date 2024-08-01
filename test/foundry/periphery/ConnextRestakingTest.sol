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

import {IConnext, MockConnext} from "../../../contracts/mocks/MockConnext.sol";

import {L1BridgeCollateral} from "../../../contracts/periphery/connext/L1BridgeCollateral.sol";
import {L2DepositCollateral} from "../../../contracts/periphery/connext/L2DepositCollateral.sol";
import {XERC20} from "../../../contracts/periphery/connext/XERC20.sol";
import {XERC20Lockbox} from "../../../contracts/periphery/connext/XERC20Lockbox.sol";
import "../base/BasePsmTest.sol";

contract ConnextRestakingTest is BasePsmTest {
  IConnext bridge;

  XERC20 localZAI;
  XERC20Lockbox lockbox;

  XERC20 remoteZAI;
  MockERC20 remoteUSDC;

  L1BridgeCollateral l1Bridge;
  L2DepositCollateral l2Bridge;

  function setUp() external {
    _setUpPSM();

    bridge = new MockConnext();

    localZAI = new XERC20();
    remoteZAI = new XERC20();
    remoteUSDC = new MockERC20("USDC", "USDC", 6);
    lockbox = new XERC20Lockbox();
    l1Bridge = new L1BridgeCollateral();
    l2Bridge = new L2DepositCollateral();

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
      remoteUSDC, // IERC20 _collateralToken,
      bridge, // IConnext _connext,
      "0x", // bytes32 _swapKey,
      100, // uint32 _bridgeDestinationDomain,
      address(l1Bridge), // address _bridgeTargetAddress,
      address(this), // address _owner,
      1e12 // uint256 _rate
    );

    // give limits
    localZAI.setLimits(address(l1Bridge), 0, 1e18 * 10_000_000);
    localZAI.setLockbox(address(lockbox));
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

  function test_l2Bridge() external {
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
}
