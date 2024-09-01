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

import {IAerodromeRouter} from "../../../../interfaces/periphery/dex/IAerodromeRouter.sol";

import {IL2DepositCollateralL0} from "../../../../interfaces/periphery/layerzero/IL2DepositCollateralL0.sol";
import {IERC20Metadata, ZapBase} from "../../ZapBase.sol";

contract ZapAerodromeBase is ZapBase {
  IL2DepositCollateralL0 public bridge;

  constructor(address _staking, address _bridge) ZapBase(_staking) {
    bridge = IL2DepositCollateralL0(_bridge);

    zai = IERC20Metadata(address(bridge.oft()));
    collateral = IERC20Metadata(address(bridge.depositToken()));

    // nothing
    zai.approve(address(pool), type(uint256).max);

    decimalOffset = 10 ** (18 - collateral.decimals());

    // give approvals
    zai.approve(address(pool), type(uint256).max);
    collateral.approve(address(pool), type(uint256).max);
    collateral.approve(address(bridge), type(uint256).max);
  }
}
