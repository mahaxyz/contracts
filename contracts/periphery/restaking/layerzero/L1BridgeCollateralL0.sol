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

import {IPegStabilityModule} from "../../../interfaces/core/IPegStabilityModule.sol";
import {OApp, Origin} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title L1BridgeCollateralL0
 * @author maha.xyz
 * @notice Credits any collateral bridged from various L2s via layerzero into the adapter for accounting purposes.
 */
contract L1BridgeCollateralL0 is AccessControlEnumerable {
  using SafeERC20 for IERC20;

  bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

  /// @notice The layerzero OFT adapter on mainnet
  address public immutable adapter;

  /// @notice The stablecoin address on mainnet
  IERC20 public immutable stablecoin;

  /// @notice The RestakeManager contract - deposits into the protocol are restaked here
  IPegStabilityModule public immutable psm;

  /// @notice The collateral token address - will be sent via bridge from L2
  IERC20 public immutable collateral;

  /// @notice The odos contract address
  address public immutable odos;

  constructor(IPegStabilityModule _psm, address _adapter) {
    require(address(_psm) != address(0), "Invalid PSM address");
    psm = _psm;
    adapter = _adapter;
    stablecoin = _psm.zai();
    collateral = _psm.collateral();
    collateral.approve(address(psm), type(uint256).max);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXECUTOR_ROLE, msg.sender);
  }

  function process() public {
    // Get the amount of collateral
    uint256 collateralAmount = collateral.balanceOf(address(this));

    // Deposit it into psm and send the tokens to the adapter
    if (collateralAmount > 0) {
      psm.mint(adapter, psm.mintAmountIn(collateralAmount));
    }
  }

  function processWithOdos(IERC20 token, bytes memory data) public onlyRole(EXECUTOR_ROLE) {
    token.approve(odos, type(uint256).max);

    // swap on odos
    (bool success,) = odos.call(data);
    require(success, "odos call failed");

    process();
  }

  function recall(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }
}
