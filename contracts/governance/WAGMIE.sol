// SPDX-License-Identifier: GPL-3.0

// ██╗    ██╗ █████╗  ██████╗ ███╗   ███╗██╗███████╗
// ██║    ██║██╔══██╗██╔════╝ ████╗ ████║██║██╔════╝
// ██║ █╗ ██║███████║██║  ███╗██╔████╔██║██║█████╗
// ██║███╗██║██╔══██║██║   ██║██║╚██╔╝██║██║██╔══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝██║ ╚═╝ ██║██║███████╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚═╝╚══════╝

// Website: https://wagmie.com
// Telegram: https://t.me/wagmiecom
// Twitter: https://x.com/wagmie_

pragma solidity 0.8.21;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract WAGMIE is ERC20Burnable, ERC20Permit {
  constructor() ERC20("WAGMIE", "WAGMIE") ERC20Permit("WAGMIE") {
    _mint(msg.sender, 1_000_000_000 * 10 ** decimals());
  }
}
