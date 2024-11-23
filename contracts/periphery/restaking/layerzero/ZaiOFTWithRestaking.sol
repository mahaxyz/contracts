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

contract ZaiOFTWithRestaking is LayerZeroCustomOFT {
  address public restaker;

  constructor(address _lzEndpoint, address _owner) LayerZeroCustomOFT("ZAI Stablecoin", "ZAI", _lzEndpoint) {
    _transferOwnership(_owner);
    endpoint.setDelegate(_owner);
    _mint(msg.sender, 69_420 ether);
    _burn(msg.sender, 69_420 ether);
  }

  function setRestakerZAI(address _restaking) external onlyOwner {
    restaker = _restaking;
  }

  function restakingMint(address _to, uint256 _amount) external {
    require(msg.sender == restaker, "!restaker");
    _mint(_to, _amount);
  }
}
