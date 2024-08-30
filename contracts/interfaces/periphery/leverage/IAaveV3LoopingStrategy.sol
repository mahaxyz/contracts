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

interface IFlashLoanReceiver {
  /**
   * @notice Executes an operation after receiving the flash-borrowed assets
   * @dev Ensure that the contract can return the debt + premium, e.g., has
   *      enough funds to repay and has approved the Pool to pull the total amount
   * @param assets The addresses of the flash-borrowed assets
   * @param amounts The amounts of the flash-borrowed assets
   * @param premiums The fee of each flash-borrowed asset
   * @param initiator The address of the flashloan initiator
   * @param params The byte-encoded params passed when initiating the flashloan
   * @return True if the execution of the operation succeeds, false otherwise
   */
  function executeOperation(
    address[] calldata assets,
    uint256[] calldata amounts,
    uint256[] calldata premiums,
    address initiator,
    bytes calldata params
  ) external returns (bool);

  function POOL() external view returns (address);
}

interface IAaveV3LoopingStrategy is IFlashLoanReceiver {
  event IncreasePos(address indexed user, address collPool, uint256 supplyAmt, address borrPool, uint256 borrAmt);
  event DecreasePos(
    address indexed user,
    address collPool,
    uint256 decreasedCollAmt,
    address borrPool,
    uint256 repaidBorrAmt,
    address tokenOut,
    uint256 amtOut
  );
  event RepayDebtWithCollateral(
    address indexed user, address collPool, uint256 decreasedCollAmt, address borrPool, uint256 repaidBorrAmt
  );
  event Swap(address indexed swapper, address from, address to, uint256 amtIn, uint256 amtOut);

  struct FlashLoanParams {
    address caller; // user who initiated the transaction
    bytes inputParams; // input params for transaction
    OPERATION operation; // operation type
  }

  struct IncreasePosParams {
    address tokenIn; // token to transfer from msg.sender
    uint256 amtIn; // amount to transfer from msg.sender
    address collPool; // collateral pool (aToken)
    address borrPool; // borrowing pool (debt token)
    uint256 borrAmt; // borrowing amount
    SwapInfo swapInfo; // swap info
  }

  struct DecreasePosParams {
    address collPool; // collateral pool (aToken)
    uint256 collAmt; // collateral amount
    address borrPool; // borrowing pool (debt token)
    uint256 debtAmt; // debt amount
    address tokenOut; // token to transfer to msg.sender
    SwapInfo swapInfo; // swap info
  }

  struct RepayDebtWithCollateralParams {
    address collPool; // collateral pool (aToken)
    uint256 collAmt; // collateral amount
    address borrPool; // borrowing pool (debt token)
    uint256 debtAmt; // debt amount
    SwapInfo swapInfo; // swap info
  }

  struct SwapInfo {
    address swapper; // swapper address for handling swap for each dex
    uint256 slippage; // slippage for swap
    bytes data; // swap data (ex: path, deadline, etc.)
  }

  enum OPERATION {
    INCREASE_POS,
    DECREASE_POS,
    REPAY_DEBT_WITH_COLLATERAL
  }

  /// @dev flash loan to execute increase position size
  function increasePos(IncreasePosParams calldata params) external;

  /// @dev flash loan to execute increase position size with native token
  function increasePosNative(IncreasePosParams calldata params) external payable;

  /// @dev flash loan to execute decrease position size
  function decreasePos(DecreasePosParams calldata params) external;

  /// @dev flash loan to execute decrease position size return native token
  function decreasePosNative(DecreasePosParams calldata params) external;

  /// @dev flash loan to execute repay debt with collateral
  function repayDebtWithCollateral(RepayDebtWithCollateralParams calldata params) external;
}
