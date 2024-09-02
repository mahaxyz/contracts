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

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract WrappedStakingLPRewards is ERC20Upgradeable {
  using SafeERC20 for IERC20;

  address public vault;
  IERC20 public underlying;
  IERC20[] public rewardTokens;

  address private _me;

  function initialize(
    string memory _name,
    string memory _symbol,
    address _vault,
    address[] memory _rewardTokens
  ) external reinitializer(1) {
    __ERC20_init(_name, _symbol);
    vault = _vault;
    underlying = IERC20(IERC4626(vault).asset());
    underlying.approve(vault, type(uint256).max);

    for (uint256 i = 0; i < _rewardTokens.length; i++) {
      rewardTokens[i] = IERC20(_rewardTokens[i]);
    }

    _me = address(this);
  }

  function deposit(uint256 _amount) external {
    for (uint256 i = 0; i < rewardTokens.length; i++) {
      IMultiStakingRewardsERC4626(vault).getReward(_me, rewardTokens[i]);
    }

    underlying.safeTransferFrom(msg.sender, address(this), _amount);
    uint256 shares = IERC4626(vault).deposit(_amount, _me);
    _mint(msg.sender, shares);
  }

  function withdraw(uint256 _amount) external {
    uint256 sharesToBurn = IERC4626(vault).previewWithdraw(_amount);
    uint256 percentageE18 = sharesToBurn * 1e18 / totalSupply();

    _burn(msg.sender, sharesToBurn);

    IERC4626(vault).withdraw(_amount, msg.sender, _me);

    for (uint256 i = 0; i < rewardTokens.length; i++) {
      IMultiStakingRewardsERC4626(vault).getReward(_me, rewardTokens[i]);
      rewardTokens[i].safeTransfer(msg.sender, rewardTokens[i].balanceOf(_me) * percentageE18 / 1e18);
    }
  }
}
