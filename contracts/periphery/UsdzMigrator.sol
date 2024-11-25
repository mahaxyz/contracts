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

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract UsdzMigrator {
  IERC20 public old;
  IERC20 public zai;

  constructor(address _old, address _zai) {
    old = IERC20(_old);
    zai = IERC20(_zai);
  }

  function migrate(uint256 amount) external {
    require(old.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    require(zai.transfer(msg.sender, amount), "Transfer failed");
  }
}
