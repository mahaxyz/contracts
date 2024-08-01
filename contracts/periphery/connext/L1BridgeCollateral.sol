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

import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";

import {ConnextErrors} from "../../interfaces/errors/ConnextErrors.sol";
import {ConnextEvents} from "../../interfaces/events/ConnextEvents.sol";
import {IL1Bridge} from "../../interfaces/periphery/IL1Bridge.sol";
import {IXERC20} from "../../interfaces/periphery/connext/IXERC20.sol";
import {IXERC20Lockbox} from "../../interfaces/periphery/connext/IXERC20Lockbox.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract L1BridgeCollateral is IL1Bridge, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice The xZAI token address
  IERC20 public xZAI;

  /// @notice The zai token address
  IERC20 public zai;

  /// @notice The RestakeManager contract - deposits into the protocol are restaked here
  IPegStabilityModule public psm;

  /// @notice The wETH token address - will be sent via bridge from L2
  IERC20 public collateral;

  /// @notice The lockbox contract for ZAI - minted ZAI is sent here
  IXERC20Lockbox public lockbox;

  /// @notice The address of the main Connext contract
  address public connext;

  /// @dev Initializes the contract with initial vars
  function initialize(
    IERC20 _zai,
    IERC20 _xZai,
    IPegStabilityModule _psm,
    IERC20 _collateral,
    IXERC20Lockbox _lockbox,
    address _connext
  ) public initializer {
    // Verify non-zero addresses on inputs
    if (
      address(_zai) == address(0) || address(_xZai) == address(0) || address(_psm) == address(0)
        || address(_collateral) == address(0) || address(_lockbox) == address(0) || address(_connext) == address(0)
    ) {
      revert ConnextErrors.InvalidZeroInput();
    }

    zai = _zai;
    xZAI = _xZai;
    psm = _psm;
    collateral = _collateral;
    lockbox = _lockbox;
    connext = _connext;

    zai.approve(address(lockbox), type(uint256).max);
    collateral.approve(address(psm), type(uint256).max);
  }

  /// @inheritdoc IL1Bridge
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory
  ) external nonReentrant returns (bytes memory) {
    // Only allow incoming messages from the Connext contract or bridge admin role
    if (msg.sender != address(connext)) {
      revert ConnextErrors.InvalidSender(address(connext), msg.sender);
    }

    // Check that the token received is collateral
    if (_asset != address(collateral)) revert ConnextErrors.InvalidTokenReceived();

    // Check that the amount sent is greater than 0
    if (_amount == 0) revert ConnextErrors.InvalidZeroInput();

    // Get the amount of collateral
    uint256 collateralAmount = collateral.balanceOf(address(this));

    // Get the amonut of zai before the deposit
    uint256 zaiBalanceBeforeDeposit = zai.balanceOf(address(this));

    // Deposit it into psm
    psm.mint(address(this), psm.mintAmountIn(collateralAmount));

    // Get the amount of zai that was minted
    uint256 zaiAmount = zai.balanceOf(address(this)) - zaiBalanceBeforeDeposit;

    // Get the xZAI balance before the deposit
    uint256 xZaiBalanceBeforeDeposit = xZAI.balanceOf(address(this));

    // Send to the lockbox to be wrapped into xZAI
    lockbox.deposit(zaiAmount);

    // Get the amount of xZAI that was minted
    uint256 xZaiAmount = xZAI.balanceOf(address(this)) - xZaiBalanceBeforeDeposit;

    // Burn it - it was already minted on the L2
    IXERC20(address(xZAI)).burn(address(this), xZaiAmount);

    // Emit the event
    emit ConnextEvents.ZaiMinted(_transferId, _amount, _origin, _originSender, zaiAmount);

    // Return 0 for success
    return new bytes(0);
  }
}
