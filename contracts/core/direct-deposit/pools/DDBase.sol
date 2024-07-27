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

import {IStablecoin} from "../../../interfaces/IStablecoin.sol";
import {IDDPool} from "../../../interfaces/core/IDDPool.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";

abstract contract DDBase is IDDPool {
  /// @notice The ZAI Stablecoin
  IStablecoin public zai;

  /// @notice The Direct Deposit module hub
  address public hub;

  function __DDBBase_init(address _zai, address _hub) internal {
    zai = IStablecoin(_zai);
    hub = _hub;
  }

  modifier onlyHub() {
    if (msg.sender != hub) revert NotAuthorized();
    _;
  }
}
