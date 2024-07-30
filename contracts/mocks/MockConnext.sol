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

import {IL1Bridge} from "../interfaces/periphery/IL1Bridge.sol";
import {IConnext} from "../interfaces/periphery/connext/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockConnext is IConnext {
  function xcall(
    uint32,
    address _to,
    address _asset,
    address,
    uint256 _amount,
    uint256,
    bytes calldata _callData
  ) external payable override returns (bytes32) {
    IERC20(_asset).transferFrom(msg.sender, _to, _amount);
    IL1Bridge(_to).xReceive(0, _amount, _asset, msg.sender, 0, _callData);
    return bytes32(0);
  }

  function xcall(
    uint32,
    address,
    address,
    address,
    uint256,
    uint256,
    bytes calldata,
    uint256
  ) external pure override returns (bytes32) {
    return bytes32(0);
  }

  function xcallIntoLocal(
    uint32,
    address,
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external payable override returns (bytes32) {
    return bytes32(0);
  }

  function swapExact(bytes32, uint256, address, address, uint256, uint256) external payable override returns (uint256) {
    return 0;
  }
}
