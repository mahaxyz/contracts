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
  function initialize(address _token, address _staking) external initializer {
    __BaseLocker_init("Locked MAHA Tokens", "MAHAX", _token, _staking, 4 * 365 * 86_400);
  }

  /// @notice Update the start date of a lock
  /// @param _id The lock id
  /// @param _startDate The new start date
  /// @dev This function can only be called by the staking contract
  function updateLockStartDate(uint256 _id, uint256 _startDate) external {
    require(msg.sender == address(staking), "!_staking");
    _locked[_id].start = _startDate;
    _locked[_id].power = _calculatePower(_locked[_id]);
  }
}
