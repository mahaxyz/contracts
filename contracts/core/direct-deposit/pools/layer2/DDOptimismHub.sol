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
 * @title A Direct Deposit Module that sends the newly minted ZAI to a hub on a layer 2 via an optimism bridge
 * @author maha.xyz
 */
contract DDOptimismHub is DDBaseL2 {
  // https://github.com/base-org/guides/blob/main/bridge/native/README.md
  function proveBridgeWithdrawal() external {
    // todo
  }

  // https://github.com/base-org/guides/blob/main/bridge/native/README.md
  function finalizeBridgeWithdrawal() external {
    // todo
  }

  function _depositToBridge(address to, uint256 amount) internal virtual override {
    // todo
  }
}
