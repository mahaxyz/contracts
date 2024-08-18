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

import {DDBaseL2} from "./DDBaseL2.sol";

/**
 * @title A Direct Deposit Module that sends the newly minted ZAI to a hub on a layer 2 via a Polygon zkEVM Bridge
 * @author maha.xyz
 */
contract DDZkPolygonEVMHub is DDBaseL2 {
  function proveBridgeWithdrawal() external {
    // todo
  }

  function finalizeBridgeWithdrawal() external {
    // todo
  }

  function _depositToBridge(address to, uint256 amount) internal virtual override {
    // todo
  }
}
