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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IL1BridgeCollateralL0 {
  function process() external;
}

contract L1RestakingSweeperCron is Ownable {
  address public usdc;
  uint256 public limit;
  IL1BridgeCollateralL0 public depositCollateralL0;

  constructor(address _usdc, uint256 _limit, address _depositCollateralL0, address _governance) Ownable(_governance) {
    usdc = _usdc;
    limit = _limit;
    depositCollateralL0 = IL1BridgeCollateralL0(_depositCollateralL0);
  }

  function setSweepLimit(uint256 _limit) public onlyOwner {
    limit = _limit;
  }

  function usdcToSweep() public view returns (uint256) {
    return IERC20(usdc).balanceOf(address(depositCollateralL0));
  }

  function shouldExecute() public view returns (bool) {
    return usdcToSweep() >= limit;
  }
}
