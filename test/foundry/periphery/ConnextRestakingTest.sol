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
import {IXERC20, XERC20} from "../../../contracts/periphery/connext/XERC20.sol";
import {XERC20Lockbox} from "../../../contracts/periphery/connext/XERC20Lockbox.sol";
import "../base/BasePsmTest.sol";

contract ConnextRestakingTest is BasePsmTest {
  IConnext bridge;

  IXERC20 localZAI;
  XERC20Lockbox lockbox;

  IXERC20 remoteZAI;
  MockERC20 remoteUSDC;

  L1BridgeCollateral l1Bridge;
  L2DepositCollateral l2Bridge;

  function setUp() external {
    _setUpPSM();

    bridge = new MockConnext();

    localZAI = new XERC20("ZAI", "xZAI", address(this));
    remoteZAI = new XERC20("ZAI", "xZAI", address(this));
    remoteUSDC = new MockERC20("USDC", "USDC", 6);
    lockbox = new XERC20Lockbox();

    l1Bridge = new L1BridgeCollateral();
    l2Bridge = new L2DepositCollateral();

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
      0, // uint32 _bridgeDestinationDomain,
      address(0), // address _bridgeTargetAddress,
      address(this), // address _owner,
      1e12 // uint256 _rate
    );
  }

  function test_bridgeRestaking() external {
    // todo
  }
}
