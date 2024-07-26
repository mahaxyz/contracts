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

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IConnext} from "../../interfaces/periphery/connext/IConnext.sol";
import {IXERC20} from "../../interfaces/periphery/connext/IXERC20.sol";
import {IL2Deposit} from "../../interfaces/periphery/IL2Deposit.sol";
import {IXERC20Lockbox} from "../../interfaces/periphery/connext/IXERC20Lockbox.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author  Renzo
 * @title   xRenzoDeposit Contract
 * @dev     Tokens are sent to this contract via deposit, xezETH is minted for the user,
 *          and funds are batched and bridged down to the L1 for depositing into the Renzo Protocol.
 *          Any ezETH minted on the L1 will be locked in the lockbox for unwrapping at a later time with xezETH.
 * @notice  Allows L2 minting of xezETH tokens in exchange for deposited assets
 */
contract L2DepositCollateral is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  IL2Deposit
{
  using SafeERC20 for IERC20;

  /// @notice The last timestamp the price was updated
  uint256 public lastPriceTimestamp;

  /// @notice The last price that was updated - denominated in ETH with 18 decimal precision
  uint256 public lastPrice;

  uint256 public rate;

  /// @notice The xezETH token address
  IERC20 public xezETH;

  /// @notice The deposit token address - this is what users will deposit to mint xezETH
  IERC20 public depositToken;

  /// @notice The collateral token address - this is what the deposit token will be swapped into and bridged to L1
  IERC20 public collateralToken;

  /// @notice The address of the main Connext contract
  IConnext public connext;

  /// @notice The swap ID for the connext token swap
  bytes32 public swapKey;

  /// @notice The receiver middleware contract address
  address public receiver;

  /// @notice The bridge router fee basis points - 100 basis points = 1%
  uint256 public bridgeRouterFeeBps;

  /// @notice The bridge destination domain - mainnet ETH connext domain
  uint32 public bridgeDestinationDomain;

  /// @notice The contract address where the bridge call should be sent on mainnet ETH
  address public bridgeTargetAddress;

  /// @notice The mapping of allowed addresses that can trigger the bridge function
  mapping(address => bool) public allowedBridgeSweepers;

  /// @dev - This contract expects all tokens to have 18 decimals for pricing
  uint8 public constant EXPECTED_DECIMALS = 18;

  /// @dev - Fee basis point, 100 basis point = 1 %
  uint32 public constant FEE_BASIS = 10000;

  // bridge fee in basis points 100 basis points = 1%
  uint256 public bridgeFeeShare;

  // Batch size for sweeping
  uint256 public sweepBatchSize;

  // Total bridge fee collected for current batch
  uint256 public bridgeFeeCollected;

  /**
   * @notice  Initializes the contract with initial vars
   * @dev     All tokens are expected to have 18 decimals
   * @param   _currentPrice  Initializes it with an initial price of ezETH to ETH
   * @param   _xezETH  L2 ezETH token
   * @param   _depositToken  WETH on L2
   * @param   _collateralToken  nextWETH on L2
   * @param   _connext  Connext contract
   * @param   _swapKey  Swap key for the connext contract swap from WETH to nextWETH
   * @param   _receiver Renzo Receiver middleware contract for price feed
   */
  function initialize(
    uint256 _currentPrice,
    IERC20 _xezETH,
    IERC20 _depositToken,
    IERC20 _collateralToken,
    IConnext _connext,
    bytes32 _swapKey,
    address _receiver,
    uint32 _bridgeDestinationDomain,
    address _bridgeTargetAddress,
    address _owner,
    uint256 _rate
  ) public initializer {
    // Initialize inherited classes
    __Ownable_init(_owner);

    // Verify valid non zero values
    if (
      _currentPrice == 0 ||
      address(_xezETH) == address(0) ||
      address(_depositToken) == address(0) ||
      address(_collateralToken) == address(0) ||
      address(_connext) == address(0) ||
      _swapKey == 0 ||
      _bridgeDestinationDomain == 0 ||
      _bridgeTargetAddress == address(0)
    ) {
      revert InvalidZeroInput();
    }

    // Initialize the price and timestamp
    lastPrice = _currentPrice;
    lastPriceTimestamp = block.timestamp;

    // Set xezETH address
    xezETH = _xezETH;

    // Set the depoist token
    depositToken = _depositToken;

    // Set the collateral token
    collateralToken = _collateralToken;

    // Set the connext contract
    connext = _connext;

    // Set the swap key
    swapKey = _swapKey;

    // Set receiver contract address
    receiver = _receiver;
    // Connext router fee is 5 basis points
    bridgeRouterFeeBps = 5;

    // Set the bridge destination domain
    bridgeDestinationDomain = _bridgeDestinationDomain;

    // Set the bridge target address
    bridgeTargetAddress = _bridgeTargetAddress;

    // set oracle Price Feed struct
    rate = _rate;

    // set bridge Fee Share 0.05% where 100 basis point = 1%
    bridgeFeeShare = 5;

    //set sweep batch size to 32 ETH
    sweepBatchSize = 32 ether;
  }

  /**
   * @notice  Accepts deposit for the user in depositToken and mints xezETH
   * @dev     This funcion allows anyone to call and deposit collateral for xezETH
   *          ezETH will be immediately minted based on the current price
   *          Funds will be held until sweep() is called.
   *          User calling this function should first approve the tokens to be pulled via transferFrom
   * @param   _amountIn  Amount of tokens to deposit
   * @param   _minOut  Minimum number of xezETH to accept to ensure slippage minimums
   * @param   _deadline  latest timestamp to accept this transaction
   * @return  uint256  Amount of xezETH minted to calling account
   */
  function deposit(
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _deadline
  ) external nonReentrant returns (uint256) {
    if (_amountIn == 0) {
      revert InvalidZeroInput();
    }
    depositToken.safeTransferFrom(msg.sender, address(this), _amountIn);
    return _deposit(_amountIn, _minOut, _deadline);
  }

  /**
   * @notice  Internal function to trade deposit tokens for nextWETH and mint xezETH
   * @dev     Deposit Tokens should be available in the contract before calling this function
   * @param   _amountIn  Amount of tokens deposited
   * @param   _minOut  Minimum number of xezETH to accept to ensure slippage minimums
   * @param   _deadline  latest timestamp to accept this transaction
   * @return  uint256  Amount of xezETH minted to calling account
   */
  function _deposit(
    uint256 _amountIn,
    uint256 _minOut,
    uint256 _deadline
  ) internal returns (uint256) {
    // calculate bridgeFee for deposit amount
    uint256 bridgeFee = getBridgeFeeShare(_amountIn);

    // subtract from _amountIn and add to bridgeFeeCollected
    _amountIn -= bridgeFee;
    bridgeFeeCollected += bridgeFee;

    // Trade deposit tokens for nextWETH
    uint256 amountOut = _trade(_amountIn, _deadline);
    if (amountOut == 0) {
      revert InvalidZeroOutput();
    }

    // // Calculate the amount of xezETH to mint - assumes 18 decimals for price and token
    uint256 xezETHAmount = (1e18 * amountOut) / rate;

    // Check that the user will get the minimum amount of xezETH
    if (xezETHAmount < _minOut) {
      revert InsufficientOutputAmount();
    }

    // Mint xezETH to the user
    IXERC20(address(xezETH)).mint(msg.sender, xezETHAmount);

    // Emit the event and return amount minted
    emit Deposit(msg.sender, _amountIn, xezETHAmount);
    return xezETHAmount;
  }

  /**
   * @notice Function returns bridge fee share for deposit
   * @param _amountIn deposit amount in terms of ETH
   */
  function getBridgeFeeShare(uint256 _amountIn) public view returns (uint256) {
    // deduct bridge Fee share
    if (_amountIn < sweepBatchSize) {
      return (_amountIn * bridgeFeeShare) / FEE_BASIS;
    }
    return (sweepBatchSize * bridgeFeeShare) / FEE_BASIS;
  }

  /**
   * @notice  Updates the price feed
   * @dev     This function will receive the price feed and timestamp from the L1 through CCIPReceiver middleware contract.
   *          It should verify the origin of the call and only allow permissioned source to call.
   * @param   _price The price of ezETH sent via L1.
   * @param   _timestamp The timestamp at which L1 sent the price.
   */
  function updatePrice(uint256 _price, uint256 _timestamp) external override {
    if (msg.sender != receiver) revert InvalidSender(receiver, msg.sender);
    _updatePrice(_price, _timestamp);
  }

  /**
   * @notice  Updates the price feed from the Owner account
   * @dev     Sets the last price and timestamp
   * @param   price  price of ezETH to ETH - 18 decimal precision
   */
  function updatePriceByOwner(uint256 price) external onlyOwner {
    return _updatePrice(price, block.timestamp);
  }

  /**
   * @notice  Internal function to update price
   * @dev     Sanity checks input values and updates prices
   * @param   _price  Current price of ezETH to ETH - 18 decimal precision
   * @param   _timestamp  The timestamp of the price update
   */
  function _updatePrice(uint256 _price, uint256 _timestamp) internal {
    // Update values and emit event
    lastPrice = _price;
    lastPriceTimestamp = _timestamp;

    emit PriceUpdated(_price, _timestamp);
  }

  /**
   * @notice  Trades deposit asset for nextWETH
   * @dev     Note that min out is not enforced here since the asset will be priced to ezETH by the calling function
   * @param   _amountIn  Amount of deposit tokens to trade for collateral asset
   * @return  _deadline Deadline for the trade to prevent stale requests
   */
  function _trade(
    uint256 _amountIn,
    uint256 _deadline
  ) internal returns (uint256) {
    // Approve the deposit asset to the connext contract
    depositToken.safeIncreaseAllowance(address(connext), _amountIn);

    // We will accept any amount of tokens out here... The caller of this function should verify the amount meets minimums
    uint256 minOut = 0;

    // Swap the tokens
    uint256 amountNextWETH = connext.swapExact(
      swapKey,
      _amountIn,
      address(depositToken),
      address(collateralToken),
      minOut,
      _deadline
    );

    // Subtract the bridge router fee
    if (bridgeRouterFeeBps > 0) {
      uint256 fee = (amountNextWETH * bridgeRouterFeeBps) / 10_000;
      amountNextWETH -= fee;
    }

    return amountNextWETH;
  }

  /**
   * @notice This function transfer the bridge fee to sweeper address
   */
  function _recoverBridgeFee() internal {
    uint256 feeCollected = bridgeFeeCollected;
    bridgeFeeCollected = 0;
    // transfer collected fee to bridgeSweeper
    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    IERC20(address(depositToken)).safeTransfer(msg.sender, feeCollected);
    emit SweeperBridgeFeeCollected(msg.sender, feeCollected);
  }

  /**
   * @notice  This function will take the balance of nextWETH in the contract and bridge it down to the L1
   * @dev     The L1 contract will unwrap, deposit in Renzo, and lock up the ezETH in the lockbox on L1
   *          This function should only be callable by permissioned accounts
   *          The caller will estimate and pay the gas for the bridge call
   */
  function sweep() public payable nonReentrant {
    // Verify the caller is whitelisted
    if (!allowedBridgeSweepers[msg.sender]) {
      revert UnauthorizedBridgeSweeper();
    }

    // Get the balance of nextWETH in the contract
    uint256 balance = collateralToken.balanceOf(address(this));

    // If there is no balance, return
    if (balance == 0) {
      revert InvalidZeroOutput();
    }

    // Approve it to the connext contract
    collateralToken.safeIncreaseAllowance(address(connext), balance);

    // Need to send some calldata so it triggers xReceive on the target
    bytes memory bridgeCallData = abi.encode(balance);

    connext.xcall{value: msg.value}(
      bridgeDestinationDomain,
      bridgeTargetAddress,
      address(collateralToken),
      msg.sender,
      balance,
      0, // Asset is already nextWETH, so no slippage will be incurred
      bridgeCallData
    );

    // send collected bridge fee to sweeper
    _recoverBridgeFee();

    // Emit the event
    emit BridgeSwept(
      bridgeDestinationDomain,
      bridgeTargetAddress,
      msg.sender,
      balance
    );
  }

  /**
   * @notice  Allows the owner to set addresses that are allowed to call the bridge() function
   * @dev     .
   * @param   _sweeper  Address of the proposed sweeping account
   * @param   _allowed  bool to allow or disallow the address
   */
  function setAllowedBridgeSweeper(
    address _sweeper,
    bool _allowed
  ) external onlyOwner {
    allowedBridgeSweepers[_sweeper] = _allowed;

    emit BridgeSweeperAddressUpdated(_sweeper, _allowed);
  }

  /**
   * @notice  Sweeps accidental ETH value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _amount  amount of native asset
   * @param   _to  destination address
   */
  function recoverNative(uint256 _amount, address _to) external onlyOwner {
    payable(_to).transfer(_amount);
  }

  /**
   * @notice  Sweeps accidental ERC20 value sent to the contract
   * @dev     Restricted to be called by the Owner only.
   * @param   _token  address of the ERC20 token
   * @param   _amount  amount of ERC20 token
   * @param   _to  destination address
   */
  function recoverERC20(
    address _token,
    uint256 _amount,
    address _to
  ) external onlyOwner {
    IERC20(_token).safeTransfer(_to, _amount);
  }

  /******************************
   *  Admin/OnlyOwner functions
   *****************************/

  function setRate(uint256 _rate) external onlyOwner {
    emit RateUpdated(rate, _rate);
    rate = _rate;
  }

  /**
   * @notice This function sets/updates the Receiver Price Feed Middleware for ezETH
   * @dev This should be permissioned call (onlyOnwer), can be set to address(0) for not configured
   * @param _receiver Receiver address
   */
  function setReceiverPriceFeed(address _receiver) external onlyOwner {
    emit ReceiverPriceFeedUpdated(_receiver, receiver);
    receiver = _receiver;
  }

  /**
   * @notice This function updates the BridgeFeeShare for depositors (must be <= 1% i.e. 100 bps)
   * @dev This should be a permissioned call (onlyOnwer)
   * @param _newShare new Bridge fee share in basis points where 100 basis points = 1%
   */
  function updateBridgeFeeShare(uint256 _newShare) external onlyOwner {
    if (_newShare > 100) revert InvalidBridgeFeeShare(_newShare);
    emit BridgeFeeShareUpdated(bridgeFeeShare, _newShare);
    bridgeFeeShare = _newShare;
  }

  /**
   * @notice This function updates the Sweep Batch Size (must be >= 32 ETH)
   * @dev This should be a permissioned call (onlyOwner)
   * @param _newBatchSize new batch size for sweeping
   */
  function updateSweepBatchSize(uint256 _newBatchSize) external onlyOwner {
    if (_newBatchSize < 32 ether) revert InvalidSweepBatchSize(_newBatchSize);
    emit SweepBatchSizeUpdated(sweepBatchSize, _newBatchSize);
    sweepBatchSize = _newBatchSize;
  }
}
