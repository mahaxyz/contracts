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

interface ILockerWithUpdate {
  function updateLockStartDate(uint256 _id, uint256 _startDate) external;
}

contract OmnichainStakingToken is OmnichainStakingBase {
  address public migrator;

  function initialize(
    address _locker,
    address _weth,
    address[] memory _rewardTokens,
    uint256 _rewardsDuration,
    address _owner,
    address _distributor
  ) external reinitializer(1) {
    super.__OmnichainStakingBase_init(
      "MAHA Voting Power", "MAHAvp", _locker, _weth, _rewardTokens, _rewardsDuration, _distributor
    );

    _transferOwnership(_owner);
  }

  function _getTokenPower(uint256 amount) internal pure override returns (uint256 power) {
    power = amount;
  }

  function setMigrator(address _migrator) external onlyOwner {
    migrator = _migrator;
  }

  function migrate(uint256 _value, uint256 _startDate, uint256 _endDate, address _who) external {
    require(msg.sender == migrator, "!migrator");

    uint256 _duration = _endDate < block.timestamp ? 2 weeks : _endDate - block.timestamp;
    uint256 id = locker.createLockFor(_value, _duration, _who, true);

    ILockerWithUpdate(address(locker)).updateLockStartDate(id, _startDate);
    _updateVotingPower(msg.sender, id);
  }
}
