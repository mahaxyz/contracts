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

import {IStablecoin} from "../../interfaces/IStablecoin.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../lib/forge-std/src/console.sol";
import {PSMErrors} from "../../interfaces/errors/PSMErrors.sol";
import {PSMEventsLib} from "../../interfaces/events/PSMEventsLib.sol";
import {IPegStabilityModule, PegStabilityModuleBase} from "./PegStabilityModuleBase.sol";

contract PegStabilityModuleYield is PegStabilityModuleBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC4626;

  function initialize(
    address _zai,
    address _collateral,
    address _governance,
    uint256 _supplyCap,
    uint256 _debtCap,
    uint256 _mintFeeBps,
    uint256 _redeemFeeBps,
    address _feeDestination
  ) external reinitializer(1) {
    __PegStabilityModule_init(
      _zai, _collateral, _governance, _supplyCap, _debtCap, _mintFeeBps, _redeemFeeBps, _feeDestination
    );
  }

  /**
   * @notice Calculates the value of assets per share in the collateral pool.
   * @dev Uses total assets and total supply from the collateral to compute the ratio.
   * @return The asset value per share in 18 decimal precision.
   */
  function rate() public view override returns (uint256) {
    return IERC4626(address(collateral)).previewDeposit(1 ether); // ZAI / sUSDe
  }

  /**
   * @notice Transfers yield from the collateral to the fee distributor if yield exceeds debt.
   * @dev Computes yield based on the collateral balance and transfers it to the fee distributor if
   *      the current value of collateral exceeds the outstanding debt.
   *      Uses `safeTransfer` to ensure secure transfer of assets.
   */
  function feesCollected() public view override returns (uint256 yield) {
    uint256 expectedCollateral = debt * rate() / 1e18; // sUSDE
    uint256 balance = collateral.balanceOf(address(this)); // sUSDE
    require(balance > expectedCollateral, "no yield to transfer");
    yield = balance - expectedCollateral; // sUSDE
  }
}
