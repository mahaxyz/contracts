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

import {ILoopingStrategy} from "../../interfaces/periphery/leverage/ILoopingStrategy.sol";
import {IMorpho} from "../../interfaces/periphery/morpho/IMorpho.sol";
import {BaseLeverage, BaseLeverageWithSwap} from "./BaseLeverageWithSwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MorphoLeverageBase
/// @author maha.xyz
/// @notice Leverages contract on Morpho
abstract contract MorphoLeverageBase is BaseLeverageWithSwap {
  IMorpho public immutable MORPHO;

  constructor(address _morpho, address _wnative) BaseLeverage(_wnative) {
    MORPHO = IMorpho(_morpho);
  }

  function _flashLoan(address borrToken, uint256 borrAmt, bytes memory inputParams, OPERATION operation) internal {
    // FlashLoanParams memory flashLoanParams =
    //   FlashLoanParams({caller: msg.sender, inputParams: inputParams, operation: operation});
    // bytes memory data = abi.encode(flashLoanParams);
    // MORPHO.flashLoan(borrToken, borrAmt, data);
  }

  function onMorphoFlashLoan(uint256 assets, bytes calldata params) external {
    // require(msg.sender == address(MORPHO));

    // // decode params
    // FlashLoanParams memory flashLoanParams = abi.decode(params, (FlashLoanParams));

    // // cases:
    // // 1.increasePos -> _executeOperationIncreasePos
    // if (flashLoanParams.operation == OPERATION.INCREASE_POS) {
    //   _executeOperationIncreasePos(flashLoanParams);
    // }
    // // 2.decreasePos -> _executeOperationDecreasePos
    // else if (flashLoanParams.operation == OPERATION.DECREASE_POS) {
    //   _executeOperationDecreasePos(flashLoanParams.flashLoanAsset, flashLoanParams.flashLoanAmt, flashLoanParams);
    // }
    // // 3.repayDebtWithCollateral -> _executeOperationRepayDebtWithCollateral
    // else if (flashLoanParams.operation == OPERATION.REPAY_DEBT_WITH_COLLATERAL) {
    //   _executeOperationRepayDebtWithCollateral(
    //     flashLoanParams.flashLoanAsset, flashLoanParams.flashLoanAmt, flashLoanParams
    //   );
    // }
    // // ensure approve asset for repay flashloan
    // _ensureApprove(flashLoanParams.flashLoanAsset, address(MORPHO), flashLoanParams.flashLoanAmt);
  }

  function _executeOperationIncreasePos(FlashLoanParams memory params) internal {
    // // decode params
    // IncreasePosParams memory increasePosParams = abi.decode(params.inputParams, (IncreasePosParams));
    // // generate swapParams
    // address borrToken = IDebtToken(increasePosParams.borrPool).UNDERLYING_ASSET_ADDRESS();
    // address collToken = IAToken(increasePosParams.collPool).UNDERLYING_ASSET_ADDRESS();
    // // swap exact in borr pool's underlying token to coll pool's underlying token
    // _swapExactIn(
    //   increasePosParams.swapInfo.swapper,
    //   borrToken,
    //   collToken,
    //   IERC20(borrToken).balanceOf(address(this)),
    //   increasePosParams.swapInfo.slippage,
    //   increasePosParams.swapInfo.data
    // );
    // // supply coll token to coll pool on onBehalfOf
    // uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    // require(supplyAmt > 0, "supplyAmt is 0");
    // _ensureApprove(collToken, address(MORPHO), supplyAmt);
  }

  function _executeOperationDecreasePos(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    FlashLoanParams memory params
  ) internal {
    // // decode params
    // DecreasePosParams memory decreasePosParams = abi.decode(params.inputParams, (DecreasePosParams));
    // address borrToken = flashLoanAsset;
    // address collToken = IAToken(decreasePosParams.collPool).UNDERLYING_ASSET_ADDRESS();
    // // repay debt and withdraw collateral
    // decreasePosParams.collAmt =
    //   _reducePos(decreasePosParams.collPool, decreasePosParams.collAmt, borrToken, flashLoanAmt, params.caller);

    // // cases:
    // // 1 tokenOut is borrPool's underlying token -> swap exact in coll pool's underlying token to borr pool's
    // underlying
    // // token
    // if (decreasePosParams.tokenOut == borrToken) {
    //   // swap all collAmt to borr pool's underlying token
    //   _swapExactIn(
    //     decreasePosParams.swapInfo.swapper,
    //     collToken,
    //     borrToken,
    //     decreasePosParams.collAmt,
    //     decreasePosParams.swapInfo.slippage,
    //     decreasePosParams.swapInfo.data
    //   );
    // }
    // // 2 tokenOut is collPool's underlying token -> swap exact out coll pool's underlying token to borr pool's
    // // underlying token
    // else {
    //   // swap exact out for repay flashloan
    //   _swapExactOut(
    //     decreasePosParams.swapInfo.swapper,
    //     collToken,
    //     borrToken,
    //     flashLoanAmt,
    //     decreasePosParams.swapInfo.slippage,
    //     decreasePosParams.swapInfo.data
    //   );
    // }
  }

  function _executeOperationRepayDebtWithCollateral(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    FlashLoanParams memory params
  ) internal {
    // // decode params
    // RepayDebtWithCollateralParams memory repayDebtWithCollateralParams =
    //   abi.decode(params.inputParams, (RepayDebtWithCollateralParams));
    // address borrToken = flashLoanAsset;
    // address collToken = IAToken(repayDebtWithCollateralParams.collPool).UNDERLYING_ASSET_ADDRESS();
    // // repay debt and withdraw collateral
    // _reducePos(
    //   repayDebtWithCollateralParams.collPool,
    //   repayDebtWithCollateralParams.collAmt,
    //   borrToken,
    //   flashLoanAmt,
    //   params.caller
    // );
    // // swap exact out for repay flashloan
    // _swapExactOut(
    //   repayDebtWithCollateralParams.swapInfo.swapper,
    //   collToken,
    //   borrToken,
    //   flashLoanAmt,
    //   repayDebtWithCollateralParams.swapInfo.slippage,
    //   repayDebtWithCollateralParams.swapInfo.data
    // );
    // // supply leftover coll token to coll pool on onBehalfOf
    // uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    // if (supplyAmt > 0) {
    //   _ensureApprove(collToken, supplyAmt);
    //   MORPHO.supplyCollateral(marketParams, assets, onBehalf, data);
    //   // IPool(POOL).supply(collToken, supplyAmt, params.caller, 0);
    // }
  }
}
