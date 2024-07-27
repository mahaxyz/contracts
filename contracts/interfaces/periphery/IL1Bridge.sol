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

interface IL1Bridge {
  /**
   * @notice  Accepts collateral from the bridge
   * @dev     This function will take all collateral and deposit it into Renzo
   *          The ezETH from the deposit will be sent to the lockbox to be wrapped into xZAI
   *          The xZAI will be burned so that the xZAI on the L2 can be unwrapped for ezETH later
   * @notice  WARNING: This function does NOT whitelist who can send funds from the L2 via Connext.  Users should NOT
   *          send funds directly to this contract.  A user who sends funds directly to this contract will cause
   *          the tokens on the L2 to become over collateralized and will be a "donation" to protocol.  Only use
   *          the deposit contracts on the L2 to send funds to this contract.
   */
  function xReceive(
    bytes32 _transferId,
    uint256 _amount,
    address _asset,
    address _originSender,
    uint32 _origin,
    bytes memory
  ) external returns (bytes memory);
}
