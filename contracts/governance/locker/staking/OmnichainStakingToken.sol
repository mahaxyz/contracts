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
import {IERC20, OmnichainStakingBase} from "./OmnichainStakingBase.sol";

interface ILockerWithUpdate {
  function updateLockDates(uint256 _id, uint256 _startDate, uint256 _endDate) external;
}

contract OmnichainStakingToken is OmnichainStakingBase {
  address public migrator;
  mapping(uint256 => bool) public migratedLockId;

  function initialize(
    address _locker,
    address _weth,
    address[] memory _rewardTokens,
    uint256 _rewardsDuration,
    address _owner,
    address _distributor
  ) external reinitializer(2) {
    super.__OmnichainStakingBase_init(
      "MAHA Voting Power", "MAHAvp", _locker, _weth, _rewardTokens, _rewardsDuration, _distributor
    );

    _transferOwnership(_owner);
  }

  function _getTokenPower(
    uint256 amount
  ) internal pure override returns (uint256 power) {
    power = amount;
  }

  function moveLockOwnership(uint256 _id, address _to) external onlyOwner {
    require(_to != address(0), "Invalid recipient");
    address from = lockedByToken[_id];
    require(from != address(0), "Token not locked");

    lockedByToken[_id] = _to;

    lockedTokenIdNfts[from] = _deleteAnElement(lockedTokenIdNfts[from], _id);
    lockedTokenIdNfts[_to].push(_id);

    // reset and burn voting power
    _burn(from, power[_id]);
    _mint(_to, power[_id]);

    emit LockOwnershipTransferred(_id, from, _to);
  }

  event LockOwnershipTransferred(uint256 indexed id, address indexed from, address indexed to);
}
