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

import {LayerZeroCustomOFT} from "./LayerZeroCustomOFT.sol";

// contract StakedZaiOFTWithRestaking is LayerZeroCustomOFT {
//   address public restaker;

//   constructor(address _lzEndpoint, address _owner) LayerZeroCustomOFT("Staked ZAI", "sZAI", _lzEndpoint) {
//     _transferOwnership(_owner);
//     endpoint.setDelegate(_owner);
//     _mint(msg.sender, 69_000 ether);
//     _burn(msg.sender, 69_000 ether);
//   }

//   function setRestakerSZAI(address _restaking) external onlyOwner {
//     restaker = _restaking;
//   }

//   function restakingMint(address _to, uint256 _amount) external {
//     require(msg.sender == restaker, "!restaker");
//     _mint(_to, _amount);
//   }
// }
