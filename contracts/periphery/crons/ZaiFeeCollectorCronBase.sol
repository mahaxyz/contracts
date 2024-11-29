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

import {IWETH} from "../../interfaces/governance/IWETH.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

abstract contract ZaiFeeCollectorCronBase is OwnableUpgradeable {
  address public gelatoooooo;
  address public odos;
  address[] public tokens;
  IERC20 public rewardToken;
  IWETH public weth;

  event EthCollected(uint256 indexed amount);
  event RevenueCollected(uint256 indexed amount);
  event RevenueDistributed(address indexed to, uint256 indexed amount);

  function __ZaiFeeCollectorCronBase_init(
    address _rewardToken,
    address _weth,
    address _odos,
    address[] memory _tokens,
    address _gelatoooooo,
    address _governance
  ) internal onlyInitializing {
    __Ownable_init(msg.sender);

    weth = IWETH(_weth);
    rewardToken = IERC20(_rewardToken);
    gelatoooooo = _gelatoooooo;

    setTokens(_tokens);
    setOdos(_odos);

    _transferOwnership(_governance);
  }

  receive() external payable {
    weth.deposit{value: msg.value}();
    emit EthCollected(msg.value);
  }

  function setOdos(address _odos) public onlyOwner {
    odos = _odos;
  }

  function balances() public view returns (uint256[] memory, address[] memory) {
    uint256[] memory amounts = new uint256[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      amounts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }

    return (amounts, tokens);
  }

  function setTokens(address[] memory _tokens) public onlyOwner {
    tokens = _tokens;
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).approve(odos, type(uint256).max);
    }
  }

  function refund(IERC20 token) public onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}
