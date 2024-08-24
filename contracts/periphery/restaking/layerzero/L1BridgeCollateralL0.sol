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
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title L1BridgeCollateralL0
 * @author maha.xyz
 * @notice Credits any collateral bridged from various L2s via layerzero into the adapter for accounting purposes.
 */
contract L1BridgeCollateralL0 is OApp {
  using SafeERC20 for IERC20;

  /// @notice The layerzero OFT adapter on mainnet
  address public immutable adapter;

  /// @notice The stablecoin address on mainnet
  IERC20 public immutable stablecoin;

  /// @notice The RestakeManager contract - deposits into the protocol are restaked here
  IPegStabilityModule public immutable psm;

  /// @notice The collateral token address - will be sent via bridge from L2
  IERC20 public immutable collateral;

  constructor(IPegStabilityModule _psm, address endpoint) OApp(endpoint, msg.sender) Ownable(msg.sender) {
    require(address(_psm) != address(0), "Invalid PSM address");
    psm = _psm;
    stablecoin = _psm.zai();
    collateral = _psm.collateral();
    collateral.approve(address(psm), type(uint256).max);
  }

  /**
   * @dev Internal function to handle the receive on the LayerZero endpoint.
   * @dev _executor The address of the executor.
   * @dev _extraData Additional data.
   */
  function _lzReceive(
    Origin calldata,
    bytes32,
    bytes calldata,
    address, /*_executor*/ // @dev unused in the default implementation.
    bytes calldata /*_extraData*/ // @dev unused in the default implementation.
  ) internal virtual override {
    // for any message that gets sent to the contract from the endpoint
    // we just simply mint ZAI with whatever collateral is sent to the contract
    process();
  }

  function process() public {
    // Get the amount of collateral
    uint256 collateralAmount = collateral.balanceOf(address(this));

    // Deposit it into psm and send the tokens to the adapter
    if (collateralAmount > 0) {
      psm.mint(adapter, psm.mintAmountIn(collateralAmount));
    }
  }

  function recall(address _token) external onlyOwner {
    IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
  }
}
