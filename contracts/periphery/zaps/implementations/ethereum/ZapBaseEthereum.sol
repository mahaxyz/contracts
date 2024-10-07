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

import {IPegStabilityModule} from "../../../../interfaces/core/IPegStabilityModule.sol";
import {ZapBase} from "../../ZapBase.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";

abstract contract ZapBaseEthereum is ZapBase {
  IPegStabilityModule public psm;

  constructor(address _staking, address _psm) ZapBase(_staking) {
    psm = IPegStabilityModule(_psm);

    zai = IERC20Metadata(address(psm.zai()));
    collateral = IERC20Metadata(address(psm.collateral()));

    decimalOffset = 10 ** (18 - collateral.decimals());

    // give approvals
    zai.approve(address(pool), type(uint256).max);
    collateral.approve(address(pool), type(uint256).max);
    collateral.approve(address(psm), type(uint256).max);
  }
}
