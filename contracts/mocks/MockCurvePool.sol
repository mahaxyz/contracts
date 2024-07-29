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

import {ICurveStableSwapNG} from "../interfaces/periphery/ICurveStableSwapNG.sol";
import {ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockCurvePool is ICurveStableSwapNG, ERC20 {
  IERC20[] tokens;

  constructor(string memory _name, string memory _symbol, IERC20[] memory _tokens) ERC20(_name, _symbol) {
    tokens = _tokens;
  }

  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
  }

  function burn(address _to, uint256 _amount) external {
    _burn(_to, _amount);
  }

  function add_liquidity(
    uint256[] memory _amounts,
    uint256 _min_mint_amount,
    address _receiver
  ) external override returns (uint256 sum) {
    for (uint256 index = 0; index < tokens.length; index++) {
      tokens[index].transferFrom(msg.sender, address(this), _amounts[index]);
      sum += _amounts[index];
    }
    _mint(_receiver, _min_mint_amount);
  }

  function calc_token_amount(uint256[] memory _amounts, bool) external view override returns (uint256 sum) {
    for (uint256 index = 0; index < tokens.length; index++) {
      sum += _amounts[index];
    }
  }
}
