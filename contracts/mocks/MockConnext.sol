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

import {IConnext} from "../interfaces/periphery/connext/IConnext.sol";

import {IL1BridgeConnext} from "../interfaces/periphery/connext/IL1BridgeConnext.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockConnext is IConnext {
  mapping(address => address) public bridgeMapping;

  function setBridgeMapping(address from, address to) external {
    bridgeMapping[from] = to;
  }

  function xcall(
    uint32,
    address _to,
    address _asset,
    address,
    uint256 _amount,
    uint256,
    bytes calldata _callData
  ) external payable override returns (bytes32) {
    IERC20(_asset).transferFrom(msg.sender, address(this), _amount);
    MockERC20(bridgeMapping[_asset]).mint(_to, _amount);
    IL1BridgeConnext(_to).xReceive(0, _amount, bridgeMapping[_asset], msg.sender, 0, _callData);
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

  function swapExact(
    bytes32,
    uint256 amountIn,
    address assetIn,
    address assetOut,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable override returns (uint256) {
    IERC20(assetIn).transferFrom(msg.sender, address(this), amountIn);
    MockERC20(assetOut).mint(msg.sender, amountIn);
    require(amountIn >= minAmountOut, "MockConnext: INSUFFICIENT_OUTPUT_AMOUNT");
    require(block.timestamp <= deadline, "MockConnext: EXPIRED");
    return amountIn;
  }
}
