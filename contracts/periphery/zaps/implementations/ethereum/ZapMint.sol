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
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapMint {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  IPegStabilityModule public psm;
  address public odos;
  IERC20 public zai;
  IERC20Metadata public collateral;
  uint256 public decimalOffset;
  address public me;

  error OdosSwapFailed();
  error CollateralTransferFailed();
  error TokenTransferFailed();

  event Zapped(
    address indexed user,
    address indexed token,
    uint256 indexed collateralAmount,
    uint256 zaiAmount,
    uint256 newStakedAmount
  );

  constructor(address _psm, address _odos) {
    psm = IPegStabilityModule(_psm);
    odos = _odos;
    zai = IERC20Metadata(address(psm.zai()));
    collateral = IERC20Metadata(address(psm.collateral()));

    decimalOffset = 10 ** (18 - collateral.decimals());
    me = address(this);

    // give approvals
    collateral.approve(address(psm), type(uint256).max);
  }

  function _sweep(IERC20 token) internal {
    uint256 tokenB = token.balanceOf(address(this));
    if (tokenB > 0 && !token.transfer(msg.sender, tokenB)) {
      revert TokenTransferFailed();
    }
  }

  function zapWithOdos(
    IERC20 swapAsset,
    uint256 swapAmount,
    uint256 minAmount,
    bytes memory odosCallData
  ) external payable {
    if (swapAsset != IERC20Metadata(address(0))) {
      swapAsset.safeTransferFrom(msg.sender, me, swapAmount);
      swapAsset.approve(odos, swapAmount);
    }

    // swap on odos
    (bool success,) = odos.call{value: msg.value}(odosCallData);
    require(success, "odos call failed");

    // mint ZAI
    uint256 zaiToMint = psm.mintAmountIn(collateral.balanceOf(me));
    psm.mint(msg.sender, zaiToMint);

    // Ensure minAmount minted
    uint256 beforeBal = zai.balanceOf(msg.sender);
    uint256 afterBal = zai.balanceOf(msg.sender);
    require(afterBal - beforeBal >= minAmount, "insufficient tokens minted");

    // sweep any dust
    _sweep(collateral);
    _sweep(swapAsset);

    emit Zapped(msg.sender, address(swapAsset), swapAmount, zaiToMint, afterBal);
  }
}
