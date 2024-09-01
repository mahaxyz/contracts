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

import {IAaveV3LoopingStrategy} from "./IAaveV3LoopingStrategy.sol";
import {ISwapper} from "./ISwapper.sol";
import {ReentrancyGuard} from "@openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin-contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin-contracts/token/ERC20/utils/SafeERC20.sol";

interface IAToken {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

interface IDebtToken {
  function UNDERLYING_ASSET_ADDRESS() external view returns (address);

  function balanceOf(address account) external view returns (uint256);
}

interface IPool {
  function flashLoan(
    address receiver,
    address[] calldata assets,
    uint256[] calldata amts,
    uint256[] calldata modes,
    address onBehalfOf,
    bytes calldata params,
    uint16 referralCode
  ) external;

  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

  function repay(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    address onBehalfOf
  ) external returns (uint256);

  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface IWNative {
  function deposit() external payable;

  function withdraw(uint256 wad) external;
}

contract AaveV3LoopingStrategy is IAaveV3LoopingStrategy, ReentrancyGuard {
  using SafeERC20 for IERC20;

  // constants variables
  uint256 private constant INTEREST_MODE_NONE = 0; // normal flashloan need to repay flashloan
  uint256 private constant INTEREST_MODE_VARIABLE = 2; // change flashloan to debt in variable interest rate mode
  // immutable variables
  address public immutable POOL;
  address public immutable WNATIVE;

  constructor(address _pool, address _wnative) {
    POOL = _pool;
    WNATIVE = _wnative;
  }

  function increasePos(IncreasePosParams calldata params) external nonReentrant {
    // transfer tokenIn from msg.sender to address this
    IERC20(params.tokenIn).safeTransferFrom(msg.sender, address(this), params.amtIn);
    _increasePos(params);
  }

  function increasePosNative(IncreasePosParams calldata params) external payable nonReentrant {
    require(params.tokenIn == WNATIVE, "AaveV3LoopingStrategy: invalid tokenIn");
    require(msg.value == params.amtIn, "AaveV3LoopingStrategy: invalid msg.value");
    // deposit native token to wnative
    IWNative(WNATIVE).deposit{value: msg.value}();
    _increasePos(params);
  }

  function decreasePos(DecreasePosParams calldata params) external nonReentrant {
    uint256 amtOut = _decreasePos(params);
    // transfer tokenOut to msg.sender
    IERC20(params.tokenOut).safeTransfer(msg.sender, amtOut);
  }

  function decreasePosNative(DecreasePosParams calldata params) external nonReentrant {
    require(params.tokenOut == WNATIVE, "AaveV3LoopingStrategy: invalid tokenOut");
    uint256 amtOut = _decreasePos(params);
    // withdraw wnative to msg.sender
    IWNative(WNATIVE).withdraw(amtOut);
    (bool success,) = payable(msg.sender).call{value: amtOut}("");
    require(success, "AaveV3LoopingStrategy: transfer native failed");
  }

  function repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) external nonReentrant {
    // prepare flashloan data
    address borrToken = IDebtToken(params.borrPool).UNDERLYING_ASSET_ADDRESS();
    uint256 callerDebt = IDebtToken(params.borrPool).balanceOf(msg.sender);
    uint256 borrAmt = params.debtAmt > callerDebt ? callerDebt : params.debtAmt;

    // note: use balance difference to calculate real vaule to emit event
    uint256 callerCollBalBf = IERC20(params.collPool).balanceOf(msg.sender);
    uint256 callerDebtBalBf = IERC20(params.borrPool).balanceOf(msg.sender);
    // flashloan borrAmt from aave v3 (using interest rate mode 0)
    // note: borrAmt will be used to repay in executeOperation and transfer caller's collAmt to swap to repay flashloan
    // left over collAmt will be transferred to msg.sender
    _flashLoan(borrToken, borrAmt, INTEREST_MODE_NONE, abi.encode(params), OPERATION.REPAY_DEBT_WITH_COLLATERAL);
    emit RepayDebtWithCollateral(
      msg.sender,
      params.collPool,
      callerCollBalBf - IERC20(params.collPool).balanceOf(msg.sender),
      params.borrPool,
      callerDebtBalBf - IDebtToken(params.borrPool).balanceOf(msg.sender)
    );
  }

  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool) {
    // verify that initiator is this contract
    require(msg.sender == POOL, "AaveV3LoopingStrategy: not pool");
    require(initiator == address(this), "AaveV3LoopingStrategy: invalid initiator");
    require(assets.length == 1, "AaveV3LoopingStrategy: invalid assets length");
    // decode params
    FlashLoanParams memory flashLoanParams = abi.decode(params, (FlashLoanParams));
    // cases:
    // 1.increasePos -> _executeOperationIncreasePos
    if (flashLoanParams.operation == OPERATION.INCREASE_POS) {
      _executeOperationIncreasePos(flashLoanParams);
    }
    // 2.decreasePos -> _executeOperationDecreasePos
    else if (flashLoanParams.operation == OPERATION.DECREASE_POS) {
      _executeOperationDecreasePos(assets[0], amts[0], premiums[0], flashLoanParams);
    }
    // 3.repayDebtWithCollateral -> _executeOperationRepayDebtWithCollateral
    else if (flashLoanParams.operation == OPERATION.REPAY_DEBT_WITH_COLLATERAL) {
      _executeOperationRepayDebtWithCollateral(assets[0], amts[0], premiums[0], flashLoanParams);
    }
    // ensure approve asset for repay flashloan
    _ensureApprove(assets[0], amts[0] + premiums[0]);
    return true;
  }

  function _increasePos(IncreasePosParams calldata params) internal {
    // verify that tokenIn is borrPool's underlying token or collPool's underlying token
    address borrToken = IDebtToken(params.borrPool).UNDERLYING_ASSET_ADDRESS();
    address collToken = IAToken(params.collPool).UNDERLYING_ASSET_ADDRESS();
    // note: use balance difference to calculate real vaule to emit event
    uint256 callerCollBalBf = IERC20(params.collPool).balanceOf(msg.sender);
    uint256 callerDebtBalBf = IDebtToken(params.borrPool).balanceOf(msg.sender);
    require(params.tokenIn == borrToken || params.tokenIn == collToken, "AaveV3LoopingStrategy: invalid tokenIn");
    // flashloan from aave v3 (using interest rate mode 2)
    // note: borr pool will be swapped to collPool's underlying token and supply in flashloan\
    _flashLoan(borrToken, params.borrAmt, INTEREST_MODE_VARIABLE, abi.encode(params), OPERATION.INCREASE_POS);
    emit IncreasePos(
      msg.sender,
      params.collPool,
      IERC20(params.collPool).balanceOf(msg.sender) - callerCollBalBf,
      params.borrPool,
      IDebtToken(params.borrPool).balanceOf(msg.sender) - callerDebtBalBf
    );
  }

  function _decreasePos(DecreasePosParams memory params) internal returns (uint256 amtOut) {
    // validate tokenOut
    address borrToken = IDebtToken(params.borrPool).UNDERLYING_ASSET_ADDRESS();
    address collToken = IAToken(params.collPool).UNDERLYING_ASSET_ADDRESS();
    require(params.tokenOut == borrToken || params.tokenOut == collToken, "AaveV3LoopingStrategy: invalid tokenOut");
    // note: use balance difference to calculate real vaule to emit event
    uint256 callerCollBalBf = IERC20(params.collPool).balanceOf(msg.sender);
    uint256 callerDebtBalBf = IDebtToken(params.borrPool).balanceOf(msg.sender);
    // take min of caller's debt and params.debtAmt
    uint256 callerDebt = IDebtToken(params.borrPool).balanceOf(msg.sender);
    uint256 borrAmt = params.debtAmt > callerDebt ? callerDebt : params.debtAmt;
    // flashloan borrAmt from aave v3 (using interest rate mode 0)
    // note: borrAmt will be used to repay in executeOperation and transfer caller's collAmt to swap to repay flashloan
    _flashLoan(borrToken, borrAmt, INTEREST_MODE_NONE, abi.encode(params), OPERATION.DECREASE_POS);
    amtOut = IERC20(params.tokenOut).balanceOf(address(this));
    emit DecreasePos(
      msg.sender,
      params.collPool,
      callerCollBalBf - IERC20(params.collPool).balanceOf(msg.sender),
      params.borrPool,
      callerDebtBalBf - IDebtToken(params.borrPool).balanceOf(msg.sender),
      params.tokenOut,
      amtOut
    );
  }

  function _flashLoan(
    address borrToken,
    uint256 borrAmt,
    uint256 interestMode,
    bytes memory inputParams,
    OPERATION operation
  ) internal {
    // prepare flashloan
    address[] memory assets = new address[](1);
    assets[0] = borrToken;
    uint256[] memory amts = new uint256[](1);
    amts[0] = borrAmt;
    uint256[] memory interestModes = new uint256[](1);
    interestModes[0] = interestMode;
    FlashLoanParams memory flashLoanParams =
      FlashLoanParams({caller: msg.sender, inputParams: inputParams, operation: operation});
    bytes memory data = abi.encode(flashLoanParams);
    // call flashloan
    IPool(POOL).flashLoan(address(this), assets, amts, interestModes, msg.sender, data, 0);
  }

  function _executeOperationIncreasePos(FlashLoanParams memory params) internal {
    // decode params
    IncreasePosParams memory increasePosParams = abi.decode(params.inputParams, (IncreasePosParams));
    // generate swapParams
    address borrToken = IDebtToken(increasePosParams.borrPool).UNDERLYING_ASSET_ADDRESS();
    address collToken = IAToken(increasePosParams.collPool).UNDERLYING_ASSET_ADDRESS();
    // swap exact in borr pool's underlying token to coll pool's underlying token
    _swapExactIn(
      increasePosParams.swapInfo.swapper,
      borrToken,
      collToken,
      IERC20(borrToken).balanceOf(address(this)),
      increasePosParams.swapInfo.slippage,
      increasePosParams.swapInfo.data
    );
    // supply coll token to coll pool on onBehalfOf
    uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    require(supplyAmt > 0, "AaveV3LoopingStrategy: supplyAmt is 0");
    _ensureApprove(collToken, supplyAmt);
    IPool(POOL).supply(collToken, supplyAmt, params.caller, 0);
  }

  function _executeOperationDecreasePos(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    uint256 flashLoanPremium,
    FlashLoanParams memory params
  ) internal {
    // decode params
    DecreasePosParams memory decreasePosParams = abi.decode(params.inputParams, (DecreasePosParams));
    address borrToken = flashLoanAsset;
    address collToken = IAToken(decreasePosParams.collPool).UNDERLYING_ASSET_ADDRESS();
    // repay debt and withdraw collateral
    decreasePosParams.collAmt =
      _reducePos(decreasePosParams.collPool, decreasePosParams.collAmt, borrToken, flashLoanAmt, params.caller);

    // cases:
    // 1 tokenOut is borrPool's underlying token -> swap exact in coll pool's underlying token to borr pool's underlying
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
        flashLoanAmt + flashLoanPremium,
        decreasePosParams.swapInfo.slippage,
        decreasePosParams.swapInfo.data
      );
    }
  }

  function _executeOperationRepayDebtWithCollateral(
    address flashLoanAsset,
    uint256 flashLoanAmt,
    uint256 flashLoanPremium,
    FlashLoanParams memory params
  ) internal {
    // decode params
    RepayDebtWithCollateralParams memory repayDebtWithCollateralParams =
      abi.decode(params.inputParams, (RepayDebtWithCollateralParams));
    address borrToken = flashLoanAsset;
    address collToken = IAToken(repayDebtWithCollateralParams.collPool).UNDERLYING_ASSET_ADDRESS();
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
      flashLoanAmt + flashLoanPremium,
      repayDebtWithCollateralParams.swapInfo.slippage,
      repayDebtWithCollateralParams.swapInfo.data
    );
    // supply leftover coll token to coll pool on onBehalfOf
    uint256 supplyAmt = IERC20(collToken).balanceOf(address(this));
    if (supplyAmt > 0) {
      _ensureApprove(collToken, supplyAmt);
      IPool(POOL).supply(collToken, supplyAmt, params.caller, 0);
    }
  }

  function _swapExactIn(
    address swapper,
    address from,
    address to,
    uint256 amtIn,
    uint256 minAmtOut,
    bytes memory data
  ) internal {
    ISwapper.SwapExactInParams memory swapExactInParams = ISwapper.SwapExactInParams({from: from, to: to, data: data});
    // transfer token to swapper
    IERC20(from).safeTransfer(swapper, amtIn);
    // call swap function on swapper
    ISwapper(swapper).swapExactIn(swapExactInParams);
    // verify that the swap was successful
    uint256 amtOut = IERC20(to).balanceOf(address(this));
    require(amtOut >= minAmtOut, "AaveV3LoopingStrategy: insufficient amtOut");
    emit Swap(swapper, from, to, amtIn, amtOut);
  }

  function _swapExactOut(
    address swapper,
    address from,
    address to,
    uint256 amtOut,
    uint256 maxAmtIn,
    bytes memory data
  ) internal {
    ISwapper.SwapExactOutParams memory swapExactOutParams = ISwapper.SwapExactOutParams({
      from: from,
      to: to,
      amtOut: amtOut - IERC20(to).balanceOf(address(this)),
      data: data
    });
    // transfer token to swapper
    uint256 tokenInBalBf = IERC20(from).balanceOf(address(this));
    IERC20(from).safeTransfer(swapper, tokenInBalBf);
    // call swap function on swapper
    ISwapper(swapper).swapExactOut(swapExactOutParams);
    // verify that the swap was successful (slippage maxAmtIn)
    uint256 amtIn = tokenInBalBf - IERC20(from).balanceOf(address(this));
    require(amtIn <= maxAmtIn, "AaveV3LoopingStrategy: exceed maxAmtIn");
    require(IERC20(to).balanceOf(address(this)) >= amtOut, "AaveV3LoopingStrategy: invalid amtOut");
    emit Swap(swapper, from, to, amtIn, amtOut);
  }

  function _ensureApprove(address _token, uint256 _amt) internal {
    if (IERC20(_token).allowance(address(this), POOL) < _amt) {
      IERC20(_token).safeApprove(POOL, type(uint256).max);
    }
  }

  // @dev repay debt and withdraw collateral
  function _reducePos(
    address collPool,
    uint256 collAmt,
    address borrToken,
    uint256 repayAmt,
    address onBehalfOf
  ) internal returns (uint256) {
    // repay debt
    // use flashloan amts to repay debt
    _ensureApprove(borrToken, repayAmt);
    IPool(POOL).repay(borrToken, repayAmt, INTEREST_MODE_VARIABLE, onBehalfOf);
    // withdraw collateral
    // transfer from collPool
    // note: becauseof aToken's rounding issue, we will use balanceOf instead of collAmt after transferFrom
    IERC20(collPool).safeTransferFrom(onBehalfOf, address(this), collAmt);
    // withdraw all collAmt from collPool
    _ensureApprove(collPool, collAmt);
    // withdraw all collPool in this contract
    return IPool(POOL).withdraw(IAToken(collPool).UNDERLYING_ASSET_ADDRESS(), type(uint256).max, address(this));
  }

  receive() external payable {
    require(msg.sender == WNATIVE, "AaveV3LoopingStrategy: not wnative");
  }
}
