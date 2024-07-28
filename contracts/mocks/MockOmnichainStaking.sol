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

import {OmnichainStakingBase} from "../governance/locker/staking/OmnichainStakingBase.sol";

contract MockOmnichainStaking is OmnichainStakingBase {
  function init() external reinitializer(1) {
    super.__OmnichainStakingBase_init(
      "TEST", "TESTvp", address(this), address(this), address(this), address(this), 0, address(0)
    );
  }

  function initWithData(
    address _locker,
    address _weth,
    address _rewardToken1,
    uint256 _rewardsDuration,
    address _distributor
  ) external reinitializer(1) {
    super.__OmnichainStakingBase_init(
      "TEST", "TESTvp", _locker, _weth, _weth, _rewardToken1, _rewardsDuration, _distributor
    );
  }

  function mint(address _to, uint256 _amount) external {
    _mint(_to, _amount);
    _delegate(_to, _to);
  }

  function burn(address _to, uint256 _amount) external {
    _burn(_to, _amount);
    _delegate(_to, _to);
  }

  function underlying() external view returns (address) {
    return address(this);
  }

  function _getTokenPower(uint256 amount) internal pure override returns (uint256 power) {
    power = amount;
  }
}
