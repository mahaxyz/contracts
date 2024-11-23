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

import {IAggregatorV3Interface} from "../../../interfaces/governance/IAggregatorV3Interface.sol";
import {ILPOracle} from "../../../interfaces/governance/ILPOracle.sol";
import {OmnichainStakingBase} from "./OmnichainStakingBase.sol";

contract OmnichainStakingToken is OmnichainStakingBase {
  function initialize(
    address _locker,
    address _zai,
    address _maha,
    uint256 _rewardsDuration,
    address _owner,
    address _distributor
  ) external reinitializer(1) {
    super.__OmnichainStakingBase_init(
      "MAHA Voting Power", "MAHAvp", _locker, _zai, _maha, _zai, _rewardsDuration, _distributor
    );

    _transferOwnership(_owner);
  }

  function _getTokenPower(uint256 amount) internal pure override returns (uint256 power) {
    power = amount;
  }
}
