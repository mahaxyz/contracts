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

import {
  IOFT,
  MessagingFee,
  MessagingReceipt,
  OFTReceipt,
  SendParam
} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

enum StargateType {
  Pool,
  OFT
}

struct Ticket {
  uint56 ticketId;
  bytes passenger;
}

/// @title Interface for Stargate.
/// @notice Defines an API for sending tokens to destination chains.
interface IStargate is IOFT {
  /// @dev This function is same as `send` in OFT interface but returns the ticket data if in the bus ride mode,
  /// which allows the caller to ride and drive the bus in the same transaction.
  function sendToken(
    SendParam calldata _sendParam,
    MessagingFee calldata _fee,
    address _refundAddress
  ) external payable returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket);

  /// @notice Returns the Stargate implementation type.
  function stargateType() external pure returns (StargateType);
}
