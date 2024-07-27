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

import {IZaiStablecoin} from "../../interfaces/IZaiStablecoin.sol";
import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ZAI Connext Arbitrage Bot
 * @author maha.xyz
 * @notice A permission-less arbitrage bot will execute an arbitrage trade cross-chain using Connext
 */
contract ZAIConnextArbitrageBot {
  IZaiStablecoin public zai;
  IPegStabilityModule public psm;

  constructor(address _zai, address _psm) {
    zai = IZaiStablecoin(_zai);
    psm = IPegStabilityModule(_psm);
  }

  /**
   * @notice Executes an arbitrage trade to mint or burn ZAI stablecoin
   */
  function arbitrage() external {
    // todo
  }

  function _buy(uint256 amount) internal {
    // todo
  }

  function _sell(uint256 amount) internal {
    // todo
  }
}
