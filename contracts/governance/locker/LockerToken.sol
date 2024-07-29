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

import {BaseLocker} from "./BaseLocker.sol";

contract LockerToken is BaseLocker {
  address public migrator;

  function init(address _token, address _staking, address _migrator) external initializer {
    __BaseLocker_init("Locked MAHA Tokens", "MAHAX", _token, _staking, 4 * 365 * 86_400);
    migrator = _migrator;
  }

  function migrateTokenFor(
    uint256 _value,
    uint256 _startDate,
    uint256 _endDate,
    address _who
  ) external returns (uint256) {
    require(msg.sender == migrator, "!migrator");

    uint256 _duration = _endDate < block.timestamp ? 2 weeks : _endDate - block.timestamp;
    uint256 id = _createLock(_value, _duration, _who, true);

    // set the start date and recalculate the power
    _locked[id].start = _startDate;
    _locked[id].power = _calculatePower(_locked[id]);

    emit LockUpdated(_locked[id], id, msg.sender);

    return id;
  }
}
