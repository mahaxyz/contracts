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

import {IDDPlan} from "../core/IDDPlan.sol";
import {IDDPool} from "../core/IDDPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title DDEventsLib
 * @author maha.xyz
 * @notice This library defines events for the Direct Deposit contract
 */
library DDEventsLib {
  // --- Events ---
  event BurnDebt(IDDPool indexed pool, uint256 amt);
  event MintDebt(IDDPool indexed pool, uint256 amt);
  event Fees(IDDPool indexed pool, uint256 amt);
}
