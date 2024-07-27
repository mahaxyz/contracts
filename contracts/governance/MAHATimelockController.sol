// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (governance/TimelockController.sol)

pragma solidity ^0.8.0;

import {
  AccessControl, AccessControlEnumerable
} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

import {TimelockController} from "@openzeppelin/contracts/governance/TimelockController.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

contract MAHATimelockController is AccessControlEnumerable, TimelockController {
  constructor(
    uint256 minDelay,
    address admin,
    address[] memory proposers
  ) TimelockController(minDelay, proposers, proposers, admin) {
    _grantRole(EXECUTOR_ROLE, address(0));
  }

  function _grantRole(
    bytes32 role,
    address account
  ) internal virtual override (AccessControlEnumerable, AccessControl) returns (bool) {
    return super._grantRole(role, account);
  }

  function _revokeRole(
    bytes32 role,
    address account
  ) internal override (AccessControlEnumerable, AccessControl) returns (bool) {
    return super._revokeRole(role, account);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override (AccessControlEnumerable, TimelockController)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}
