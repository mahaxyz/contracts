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
 * @title ZAI Arbitrage Bot
 * @author maha.xyz
 * @notice A permission-less arbitrage bot that can mint and burn ZAI stablecoin and maintain the peg using the PSM
 * module
 * @dev This uses the odos router to swap tokens
 */
contract ZAIArbitrageBot {
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
    //
    // todo
    // uint256 zaiBalance = zai.balanceOf(address(this));
    // uint256 zaiSupply = zai.totalSupply();
    // uint256 zaiPrice = psm.zaiPrice();
    // uint256 zaiDebt = psm.zaiDebt();

    // if (zaiBalance > zaiSupply) {
    //   // Mint ZAI
    //   uint256 amount = zaiBalance - zaiSupply;
    //   uint256 debt = (amount * zaiPrice) / 1e18;
    //   require(debt > zaiDebt, "ZAIArbitrageBot: arbitrage debt too low");
    //   zai.mint(address(this), amount);
    //   zai.approve(address(psm), amount);
    //   psm.mint(amount);
    // } else if (zaiBalance < zaiSupply) {
    //   // Burn ZAI
    //   uint256 amount = zaiSupply - zaiBalance;
    //   uint256 debt = (amount * zaiPrice) / 1e18;
    //   require(debt < zaiDebt, "ZAIArbitrageBot: arbitrage debt too high");
    //   psm.burn(amount);
    //   zai.burn(amount);
    // }
  }

  function _buy(uint256 amount) internal {
    // todo
  }

  function _sell(uint256 amount) internal {
    // todo
  }
}
