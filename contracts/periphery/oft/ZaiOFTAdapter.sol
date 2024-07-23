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

import {OFTAdapter} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFTAdapter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Zai OFT Adapter
 * @author maha.xyz
 */
contract ZaiOFTAdapter is OFTAdapter {
  /**
   * Initializes the stablecoin and sets the LZ endpoint
   * @param _layerZeroEndpoint the layerzero endpoint
   * @param _delegate the layerzero delegate
   */
  constructor(
    address _zai,
    address _layerZeroEndpoint,
    address _delegate,
    address _owner
  ) OFTAdapter(_zai, _layerZeroEndpoint, _delegate) Ownable(_owner) {
    // nothing
  }
}
