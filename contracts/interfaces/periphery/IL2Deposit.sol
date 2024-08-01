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

import {IConnext} from "./connext/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IL2Deposit {
  /**
   * @notice  Initializes the contract with initial vars
   * @dev     All tokens are expected to have 18 decimals
   * @param   _xZAI  L2 ZAI token
   * @param   _depositToken  WETH on L2
   * @param   _collateralToken  nextUSDC on L2
   * @param   _connext  Connext contract
   * @param   _swapKey  Swap key for the connext contract swap from WETH to nextUSDC
   */
  function initialize(
    IERC20 _xZAI,
    IERC20 _depositToken,
    IERC20 _collateralToken,
    IConnext _connext,
    bytes32 _swapKey,
    uint32 _bridgeDestinationDomain,
    address _bridgeTargetAddress,
    address _owner,
    uint256 _rate,
    uint256 _sweepBatchSize
  ) external;

  /**
   * @notice  Accepts deposit for the user in depositToken and mints xZAI
   * @dev     This funcion allows anyone to call and deposit collateral for xZAI
   *          ZAI will be immediately minted based on the current price
   *          Funds will be held until sweep() is called.
   *          User calling this function should first approve the tokens to be pulled via transferFrom
   * @param   _amountIn  Amount of tokens to deposit
   * @param   _minOut  Minimum number of xZAI to accept to ensure slippage minimums
   * @param   _deadline  latest timestamp to accept this transaction
   * @return  uint256  Amount of xZAI minted to calling account
   */
  function deposit(uint256 _amountIn, uint256 _minOut, uint256 _deadline) external returns (uint256);

  /**
   * @notice Function returns bridge fee share for deposit
   * @param _amountIn deposit amount in terms of ETH
   */
  function getBridgeFeeShare(uint256 _amountIn) external view returns (uint256);

  /**
   * @notice  This function will take the balance of nextUSDC in the contract and bridge it down to the L1
   * @dev     The L1 contract will unwrap, deposit in maha, and lock up the ZAI in the lockbox on L1
   *          This function should only be callable by permissioned accounts
   *          The caller will estimate and pay the gas for the bridge call
   */
  function sweep() external payable;

  /**
   * @notice  Allows the owner to set addresses that are allowed to call the bridge() function
   * @param   _sweeper  Address of the proposed sweeping account
   * @param   _allowed  bool to allow or disallow the address
   */
  function setAllowedBridgeSweeper(address _sweeper, bool _allowed) external;

  /**
   * @notice  Sweeps accidental ETH value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _amount  amount of native asset
   * @param   _to  destination address
   */
  function recoverNative(uint256 _amount, address _to) external;

  /**
   * @notice  Sweeps accidental ERC20 value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _token  address of the ERC20 token
   * @param   _amount  amount of ERC20 token
   * @param   _to  destination address
   */
  function recoverERC20(address _token, uint256 _amount, address _to) external;

  /**
   * @notice This function updates the rate for the deposit
   * @param _rate The new rate for the deposit
   */
  function setRate(uint256 _rate) external;

  /**
   * @notice This function updates the BridgeFeeShare for depositors (must be <= 1% i.e. 100 bps)
   * @dev This should be a permissioned call (onlyOnwer)
   * @param _newShare new Bridge fee share in basis points where 100 basis points = 1%
   */
  function updateBridgeFeeShare(uint256 _newShare) external;

  /**
   * @notice This function updates the Sweep Batch Size
   * @dev This should be a permissioned call (onlyOwner)
   * @param _newBatchSize new batch size for sweeping
   */
  function updateSweepBatchSize(uint256 _newBatchSize) external;
}
