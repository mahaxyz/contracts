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
import {ILocker} from "../../../../interfaces/governance/ILocker.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title ZapSafetyPool
 * @dev This contract allows users to directly stake into the safety pool
 */
contract ZapSafetyPool {
  using SafeERC20 for IERC20;

  /// @notice The safety pool contract
  IERC4626 public safetyPool;

  /// @notice The ZAI stablecoin
  IERC20 public zai;

  /// @dev The address of this contract
  address private me;

  address public odos;

  error TokenTransferFailed();
  error ZaiTransferFailed();

  /**
   * @dev Initializes the contract with the required contracts
   */
  constructor(address _safetyPool, address _zai, address _odos) {
    safetyPool = IERC4626(_safetyPool);
    zai = IERC20(_zai);
    me = address(this);
    odos = _odos;
    zai.approve(_safetyPool, type(uint256).max);
  }

  /**
   * @notice Allows a user to zap into the safety pool
   * @param psm The Peg Stability Module for the asset
   * @param amountIn The amount to zap
   */
  function zapIntoSafetyPool(IPegStabilityModule psm, uint256 amountIn) external {
    uint256 zaiToMint = psm.mintAmountIn(amountIn);
    IERC20 asset = IERC20(psm.collateral());

    asset.safeTransferFrom(msg.sender, me, amountIn);
    asset.approve(address(psm), amountIn);
    psm.mint(me, zaiToMint);

    safetyPool.deposit(zaiToMint, msg.sender);

    // sweep any dust
    sweep(asset);
  }

  function zapIntoSafetyPoolWithOdos(
    IPegStabilityModule psm,
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minShares,
    bytes memory odosCallData
  ) external payable {
    if (swapAsset != IERC20(address(0))) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      swapAsset.forceApprove(odos, swapAmount);
    }

    // swap on odos
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "odos call failed");

    // mint ZAI
    IERC20 asset = IERC20(psm.collateral());
    uint256 zaiToMint = psm.mintAmountIn(asset.balanceOf(me));
    asset.approve(address(psm), type(uint256).max);
    psm.mint(me, zaiToMint);

    // mint sZAI
    uint256 shares = safetyPool.deposit(zaiToMint, msg.sender);
    require(shares >= minShares, "insufficient tokens minted");

    // sweep any dust
    sweep(asset);
  }

  function sweep(IERC20 token) public {
    uint256 zaiB = zai.balanceOf(address(this));
    uint256 tokenB = token.balanceOf(address(this));

    if (zaiB > 0 && !zai.transfer(msg.sender, zaiB)) {
      revert ZaiTransferFailed();
    }

    if (tokenB > 0 && !token.transfer(msg.sender, tokenB)) {
      revert TokenTransferFailed();
    }
  }
}
