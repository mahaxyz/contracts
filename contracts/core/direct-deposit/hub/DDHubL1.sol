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
 * @title A Direct Deposit Hub
 * @author maha.xyz
 * @notice This is the main contract responsible for managing pools.
 */
contract DDHubL1 is DDHubBase {
  function _mint(uint256 amount, address dest) internal virtual override {
    zai.mint(dest, amount);
  }

  function _burn(uint256 amount, address dest) internal virtual override {
    zai.burn(dest, amount);
  }
}
