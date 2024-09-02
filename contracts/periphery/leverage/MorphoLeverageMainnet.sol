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
import {IMorpho, IMorphoBase} from "../../interfaces/periphery/morpho/IMorpho.sol";
import {BaseLeverage, BaseLeverageWithSwap} from "./BaseLeverageWithSwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title MorphoLeverageMainnet
/// @author maha.xyz
/// @notice Leverages contract on Morpho
abstract contract MorphoLeverageMainnet is BaseLeverageWithSwap {
  IMorpho public immutable MORPHO;
  IMorphoBase.Id public marketId;
  IMorpho.MarketParams public marketParams;

  constructor(address _morpho, IMorpho.MarketParams memory _marketParams, address _wnative) BaseLeverage(_wnative) {
    MORPHO = IMorpho(_morpho);
    marketParams = _marketParams;

    // marketParams to ID via https://github.com/morpho-org/morpho-blue/blob/main/src/libraries/MarketParamsLib.sol
    uint256 marketParamsBytesLength = 5 * 32;
    IMorphoBase.Id _marketId;
    assembly ("memory-safe") {
      _marketId := keccak256(_marketParams, marketParamsBytesLength)
    }
    marketId = _marketId;
  }

  function _increasePos(IncreasePosParams calldata params) internal override {
    // verify that tokenIn is borrPool's underlying token or collPool's underlying token
    address borrToken = params.borrPool;
    address collToken = params.collPool;

    // note: use balance difference to calculate real vaule to emit event
    IMorpho.Position memory position = MORPHO.position(marketId, msg.sender);
    uint256 callerCollBalBf = position.supplyShares; // todo need to convert shares into amount
    uint256 callerDebtBalBf = position.borrowShares;

    require(params.tokenIn == borrToken || params.tokenIn == collToken, "invalid tokenIn");

    // note: borr pool will be swapped to collPool's underlying token and supply in flashloan\
    _flashLoan(borrToken, params.borrAmt, abi.encode(params), OPERATION.INCREASE_POS);

    IMorpho.Position memory positionAfter = MORPHO.position(marketId, msg.sender);

    emit IncreasePos(
      msg.sender,
      params.collPool,
      positionAfter.supplyShares - callerCollBalBf,
      params.borrPool,
      positionAfter.borrowShares - callerDebtBalBf
    );
  }

  function _decreasePos(DecreasePosParams memory params) internal override returns (uint256 amtOut) {
    // validate tokenOut
    address borrToken = params.borrPool;
    address collToken = params.collPool;

    require(params.tokenOut == borrToken || params.tokenOut == collToken, "LoopingStrategy: invalid tokenOut");

    // note: use balance difference to calculate real vaule to emit event
    IMorpho.Position memory position = MORPHO.position(marketId, msg.sender);
    uint256 callerCollBalBf = position.supplyShares; // todo need to convert shares into amount
    uint256 callerDebtBalBf = position.borrowShares;

    // take min of caller's debt and params.debtAmt
    uint256 borrAmt = params.debtAmt > callerDebtBalBf ? callerDebtBalBf : params.debtAmt;

    // flashloan borrAmt from aave v3 (using interest rate mode 0)
    // note: borrAmt will be used to repay in executeOperation and transfer caller's collAmt to swap to repay flashloan
    _flashLoan(borrToken, borrAmt, abi.encode(params), OPERATION.DECREASE_POS);
    amtOut = IERC20(params.tokenOut).balanceOf(address(this));
    emit DecreasePos(
      msg.sender,
      params.collPool,
      callerCollBalBf - callerCollBalBf,
      params.borrPool,
      callerDebtBalBf - callerDebtBalBf,
      params.tokenOut,
      amtOut
    );
  }

  function _repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) internal override nonReentrant {
    // prepare flashloan data
    address borrToken = params.borrPool;

    // note: use balance difference to calculate real vaule to emit event
    IMorpho.Position memory position = MORPHO.position(marketId, msg.sender);
    uint256 callerCollBalBf = position.supplyShares; // todo need to convert shares into amount
    uint256 callerDebtBalBf = position.borrowShares;

    uint256 borrAmt = params.debtAmt > callerDebtBalBf ? callerDebtBalBf : params.debtAmt;

    // flashloan borrAmt from aave v3 (using interest rate mode 0)
    // note: borrAmt will be used to repay in executeOperation and transfer caller's collAmt to swap to repay flashloan
    // left over collAmt will be transferred to msg.sender
    _flashLoan(borrToken, borrAmt, abi.encode(params), OPERATION.REPAY_DEBT_WITH_COLLATERAL);
    emit RepayDebtWithCollateral(
      msg.sender, params.collPool, callerCollBalBf - callerCollBalBf, params.borrPool, callerDebtBalBf - callerDebtBalBf
    );
  }

  function _flashLoan(
    address flashLoanToken,
    uint256 flashLoanAmt,
    bytes memory inputParams,
    OPERATION operation
  ) internal {
    FlashLoanParams memory flashLoanParams = FlashLoanParams({
      caller: msg.sender,
      inputParams: inputParams,
      flashLoanToken: flashLoanToken,
      flashLoanAmt: flashLoanAmt,
      operation: operation
    });
    bytes memory data = abi.encode(flashLoanParams);
    MORPHO.flashLoan(flashLoanToken, flashLoanAmt, data);
  }

  function onMorphoFlashLoan(uint256 assets, bytes calldata params) external {
    require(msg.sender == address(MORPHO));

    // decode params
    FlashLoanParams memory flashLoanParams = abi.decode(params, (FlashLoanParams));

    // cases:
    // 1.increasePos -> _executeOperationIncreasePos
    if (flashLoanParams.operation == OPERATION.INCREASE_POS) {
      _executeOperationIncreasePos(flashLoanParams);
    }
    // 2.decreasePos -> _executeOperationDecreasePos
    else if (flashLoanParams.operation == OPERATION.DECREASE_POS) {
      _executeOperationDecreasePos(flashLoanParams.flashLoanToken, assets, flashLoanParams);
    }
    // 3.repayDebtWithCollateral -> _executeOperationRepayDebtWithCollateral
    else if (flashLoanParams.operation == OPERATION.REPAY_DEBT_WITH_COLLATERAL) {
      _executeOperationRepayDebtWithCollateral(flashLoanParams.flashLoanToken, assets, flashLoanParams);
    }

    // ensure approve asset for repay flashloan
    _ensureApprove(flashLoanParams.flashLoanToken, address(MORPHO), assets);
  }

  function _executeOperationIncreasePos(FlashLoanParams memory params) internal {
    // decode params
    IncreasePosParams memory increasePosParams = abi.decode(params.inputParams, (IncreasePosParams));

    // generate swapParams
    address borrToken = params.flashLoanToken;
    address collToken = increasePosParams.collPool;

    // swap exact in borr pool's underlying token to coll pool's underlying token
    _swapExactIn(
      increasePosParams.swapInfo.swapper,
      borrToken,
      collToken,
      IERC20(borrToken).balanceOf(address(this)),
      increasePosParams.swapInfo.slippage,
      increasePosParams.swapInfo.data
    );

    // supply coll token to MORPHO
    uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    require(supplyAmt > 0, "supplyAmt is 0");
    _ensureApprove(collToken, address(MORPHO), supplyAmt);
    MORPHO.supplyCollateral(marketParams, supplyAmt, params.caller, "");

    // borrow to repay the debt
    MORPHO.borrow(marketParams, params.flashLoanAmt, 0, params.caller, params.caller);
  }

  function _executeOperationDecreasePos(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    FlashLoanParams memory params
  ) internal {
    // decode params
    DecreasePosParams memory decreasePosParams = abi.decode(params.inputParams, (DecreasePosParams));
    address borrToken = params.flashLoanToken;
    address collToken = decreasePosParams.collPool;

    // repay debt and withdraw collateral
    decreasePosParams.collAmt =
      _reducePos(decreasePosParams.collPool, decreasePosParams.collAmt, borrToken, flashLoanAmt, params.caller);

    // cases:
    // 1 tokenOut is borrPool's underlying token -> swap exact in coll pool's underlying token to borr pool'
    // token
    if (decreasePosParams.tokenOut == borrToken) {
      // swap all collAmt to borr pool's underlying token
      _swapExactIn(
        decreasePosParams.swapInfo.swapper,
        collToken,
        borrToken,
        decreasePosParams.collAmt,
        decreasePosParams.swapInfo.slippage,
        decreasePosParams.swapInfo.data
      );
    }
    // 2 tokenOut is collPool's underlying token -> swap exact out coll pool's underlying token to borr pool's
    // underlying token
    else {
      // swap exact out for repay flashloan
      _swapExactOut(
        decreasePosParams.swapInfo.swapper,
        collToken,
        borrToken,
        flashLoanAmt,
        decreasePosParams.swapInfo.slippage,
        decreasePosParams.swapInfo.data
      );
    }
  }

  function _executeOperationRepayDebtWithCollateral(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    FlashLoanParams memory params
  ) internal {
    // decode params
    RepayDebtWithCollateralParams memory repayDebtWithCollateralParams =
      abi.decode(params.inputParams, (RepayDebtWithCollateralParams));
    address borrToken = flashLoanAsset;
    address collToken = repayDebtWithCollateralParams.collPool;

    // repay debt and withdraw collateral
    _reducePos(
      repayDebtWithCollateralParams.collPool,
      repayDebtWithCollateralParams.collAmt,
      borrToken,
      flashLoanAmt,
      params.caller
    );

    // swap exact out for repay flashloan
    _swapExactOut(
      repayDebtWithCollateralParams.swapInfo.swapper,
      collToken,
      borrToken,
      flashLoanAmt,
      repayDebtWithCollateralParams.swapInfo.slippage,
      repayDebtWithCollateralParams.swapInfo.data
    );

    // supply leftover coll token to coll pool on onBehalfOf
    uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    if (supplyAmt > 0) {
      _ensureApprove(collToken, address(MORPHO), supplyAmt);
      MORPHO.supplyCollateral(marketParams, supplyAmt, params.caller, "");
    }
  }

  /// @dev repay debt and withdraw collateral
  function _reducePos(
    address collPool,
    uint256 collAmt,
    address borrToken,
    uint256 repayAmt,
    address onBehalfOf
  ) internal override returns (uint256) {
    _ensureApprove(borrToken, address(MORPHO), repayAmt);
    MORPHO.repay(marketParams, repayAmt, 0, onBehalfOf, "");
    MORPHO.withdrawCollateral(marketParams, collAmt, onBehalfOf, address(this));
    return IERC20(collPool).balanceOf(address(this));
  }
}
