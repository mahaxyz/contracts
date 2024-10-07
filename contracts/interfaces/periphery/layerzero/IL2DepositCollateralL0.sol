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

import {IERC20, IStablecoinOFT} from "../IStablecoinOFT.sol";
import {IStargate} from "./IStargate.sol";

interface IL2DepositCollateralL0 {
  /// @notice The rate at which the deposit token is converted to OFT
  function rate() external view returns (uint256);

  /// @notice The slippage allowed for the bridge
  function slippage() external view returns (uint256);

  /// @notice The OFT token address
  function oft() external view returns (IStablecoinOFT);

  /// @notice The deposit token address - this is what users will deposit to mint the OFT
  function depositToken() external view returns (IERC20);

  /// @notice The address of the stargate bridge
  function stargate() external view returns (IStargate);

  /// @notice The contract address where the bridge call should be sent on mainnet ETH
  function bridgeTargetAddress() external view returns (bytes32);

  /// @notice The mapping of allowed addresses that can trigger the bridge function
  // mapping(address => bool) public allowedBridgeSweepers;

  function allowedBridgeSweepers(address) external view returns (bool);

  event Deposit(address from, uint256 amountIn, uint256 amountOut);

  event BridgeSwept(bytes32 bridgeTargetAddress, address caller, uint256 balance);

  function initialize(
    IStablecoinOFT _oft,
    IERC20 _depositToken,
    IStargate _stargate,
    bytes32 _bridgeTargetAddress,
    address _governance,
    uint256 _rate,
    uint256 _slippage
  ) external;

  function deposit(uint256 _amountIn) external returns (uint256 amountOut);

  function sweep(uint256 amount) external payable;
}
