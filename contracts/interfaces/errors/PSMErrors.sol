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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PSMErrors
 * @author maha.xyz
 * @notice This library defines errors for the PSM contract
 */
library PSMErrors {
  /// @notice Error when supply cap is reached
  error SupplyCapReached();

  /// @notice Error when debt cap is reached
  error DebtCapReached();

  /// @notice Error when address is not set
  error NotZeroAddress();

  /// @notice Error when value is zero
  error NotZeroValue();
}
