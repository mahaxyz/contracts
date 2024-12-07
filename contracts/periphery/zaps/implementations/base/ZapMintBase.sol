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

import {IL2DepositCollateralL0} from "../../../../interfaces/periphery/layerzero/IL2DepositCollateralL0.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ZapMintBase {
  using SafeERC20 for IERC20;
  using SafeERC20 for IERC20Metadata;

  IL2DepositCollateralL0 public restaker;
  address public odos;
  IERC20 public zai;
  IERC20Metadata public collateral;
  uint256 public decimalOffset;
  address public me;

  error OdosSwapFailed();
  error CollateralTransferFailed();
  error TokenTransferFailed();

  event Zapped(address indexed user, address indexed token, uint256 indexed collateralAmount, uint256 zaiAmount);

  constructor(address _restaker, address _odos) {
    restaker = IL2DepositCollateralL0(_restaker);
    odos = _odos;
    zai = IERC20Metadata(address(restaker.oft()));
    collateral = IERC20Metadata(address(restaker.depositToken()));

    decimalOffset = 10 ** (18 - collateral.decimals());
    me = address(this);

    // give approvals
    collateral.approve(address(restaker), type(uint256).max);
  }

  function _sweep(IERC20 token) internal {
    if (token == IERC20(address(0))) {
      payable(msg.sender).transfer(address(this).balance);
      return;
    }
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
      swapAsset.forceApprove(odos, swapAmount);
    }

    if (swapAsset != collateral) {
      // swap on odos
      (bool success,) = odos.call{value: msg.value}(odosCallData);
      require(success, "odos call failed");
      _sweep(swapAsset);
    }

    // mint ZAI
    uint256 zaiToMint = restaker.deposit(collateral.balanceOf(me));
    require(zaiToMint >= minAmount, "insufficient tokens minted");
    zai.safeTransfer(msg.sender, zaiToMint);

    // sweep any dust
    _sweep(collateral);

    emit Zapped(msg.sender, address(swapAsset), swapAmount, zaiToMint);
  }
}
