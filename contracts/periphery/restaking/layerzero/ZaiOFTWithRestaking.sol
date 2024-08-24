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

import {LayerZeroCustomOFT} from "./LayerZeroCustomOFT.sol";

contract ZaiOFTWithRestaking is LayerZeroCustomOFT {
  address public restaker;

  constructor(
    string memory name,
    string memory symbol,
    address _lzEndpoint
  ) LayerZeroCustomOFT(name, symbol, _lzEndpoint) {}

  function setRestaker(address _restaking) external onlyOwner {
    restaker = _restaking;
  }

  function restakingMint(address _to, uint256 _amount) external {
    require(msg.sender == restaker, "!restaker");
    _mint(_to, _amount);
  }
}
