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
  function init(
    address _locker,
    address _zeroToken,
    address _poolVoter,
    uint256 _rewardsDuration,
    address _owner,
    address _distributor
  ) external reinitializer(5) {
    super.__OmnichainStakingBase_init(
      "ZERO Voting Power",
      "ZEROvp",
      _locker,
      _zeroToken,
      _poolVoter,
      _rewardsDuration,
      _distributor
    );

    _transferOwnership(_owner);
  }

  function _getTokenPower(
    uint256 amount
  ) internal pure override returns (uint256 power) {
    power = amount;
  }
}
