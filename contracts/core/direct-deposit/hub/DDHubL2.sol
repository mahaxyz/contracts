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

import {DDHubBase} from "./DDHubBase.sol";

/**
 * @title A L2 Direct Deposit Hub
 * @author maha.xyz
 * @notice This is the main contract responsible for managing pools on layer 2s.
 * @dev Holds bridged ZAI from the L1
 */
contract DDHubL2 is DDHubBase {
  uint256 minted;

  function _mint(uint256 amount, address dest) internal virtual override {
    minted += amount;
    zai.transfer(dest, amount);
  }

  function _burn(uint256 amount, address dest) internal virtual override {
    minted -= amount;
    zai.transferFrom(dest, address(this), amount);

    // todo on burn send the zai tokens back to the bridge
  }
}
