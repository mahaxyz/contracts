// SPDX-License-Identifier: GPL-3.0

// ███╗   ███╗ █████╗ ██╗  ██╗ █████╗
// ████╗ ████║██╔══██╗██║  ██║██╔══██╗
// ██╔████╔██║███████║███████║███████║
// ██║╚██╔╝██║██╔══██║██╔══██║██╔══██║
// ██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██║
// ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝

// The Stable Money of the Ethermind

// Website: https://maha.xyz
// Discord: https://discord.gg/mahadao
// Twitter: https://twitter.com/mahaxyz_

pragma solidity 0.8.21;

import {StablecoinBase} from "./StablecoinBase.sol";

/**
 * @title Zai Stablecoin "USDz"
 * @author maha.xyz
 * @notice Represents the ZAI stablecoin.
 */
contract ZaiStablecoin is StablecoinBase {
  constructor(address _owner) StablecoinBase("ZAI Stablecoin", "ZAI", _owner) {
    // nothing
  }
}
