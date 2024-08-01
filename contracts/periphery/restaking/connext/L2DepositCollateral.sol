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

import {ConnextErrors} from "../../../interfaces/errors/ConnextErrors.sol";
import {ConnextEvents} from "../../../interfaces/events/ConnextEvents.sol";
import {IConnext, IL2Deposit} from "../../../interfaces/periphery/IL2Deposit.sol";
import {IXERC20} from "../../../interfaces/periphery/connext/IXERC20.sol";
import {IXERC20Lockbox} from "../../../interfaces/periphery/connext/IXERC20Lockbox.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author  maha.xyz
 * @title   L2DepositCollateral Contract
 * @dev     Tokens are sent to this contract via deposit, xZAI is minted for the user,
 *          and funds are batched and bridged down to the L1 for depositing into the maha protocol.
 *          Any ZAI minted on the L1 will be locked in the lockbox for unwrapping at a later time with xZAI.
 * @notice  Allows L2 minting of xZAI tokens in exchange for deposited assets
 */
contract L2DepositCollateral is OwnableUpgradeable, ReentrancyGuardUpgradeable, IL2Deposit {
  using SafeERC20 for IERC20;

  uint256 public rate;

  /// @notice The xZAI token address
  IERC20 public xZAI;

  /// @notice The deposit token address - this is what users will deposit to mint xZAI
  IERC20 public depositToken;

  /// @notice The collateral token address - this is what the deposit token will be swapped into and bridged to L1
  IERC20 public collateralToken;

  /// @notice The address of the main Connext contract
  IConnext public connext;

  /// @notice The swap ID for the connext token swap
  bytes32 public swapKey;

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
  uint32 public constant FEE_BASIS = 10_000;

  // bridge fee in basis points 100 basis points = 1%
  uint256 public bridgeFeeShare;

  // Batch size for sweeping
  uint256 public sweepBatchSize;

  // Total bridge fee collected for current batch
  uint256 public bridgeFeeCollected;

  /// @inheritdoc IL2Deposit
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
  ) public initializer {
    // Initialize inherited classes
    __Ownable_init(_owner);

    // Verify valid non zero values
    if (
      address(_xZAI) == address(0) || address(_depositToken) == address(0) || address(_collateralToken) == address(0)
        || address(_connext) == address(0) || _bridgeDestinationDomain == 0 || _bridgeTargetAddress == address(0)
    ) {
      revert ConnextErrors.InvalidZeroInput();
    }

    xZAI = _xZAI;
    depositToken = _depositToken;
    collateralToken = _collateralToken;
    connext = _connext;
    swapKey = _swapKey;
    bridgeRouterFeeBps = 5;
    bridgeDestinationDomain = _bridgeDestinationDomain;
    bridgeTargetAddress = _bridgeTargetAddress;
    rate = _rate;
    bridgeFeeShare = 5;
    sweepBatchSize = _sweepBatchSize;
  }

  /// @inheritdoc IL2Deposit
  function deposit(uint256 _amountIn, uint256 _minOut, uint256 _deadline) external nonReentrant returns (uint256) {
    if (_amountIn == 0) {
      revert ConnextErrors.InvalidZeroInput();
    }
    depositToken.safeTransferFrom(msg.sender, address(this), _amountIn);
    return _deposit(_amountIn, _minOut, _deadline);
  }

  /// @inheritdoc IL2Deposit
  function getBridgeFeeShare(uint256 _amountIn) public view returns (uint256) {
    // deduct bridge Fee share
    if (_amountIn < sweepBatchSize) {
      return (_amountIn * bridgeFeeShare) / FEE_BASIS;
    }
    return (sweepBatchSize * bridgeFeeShare) / FEE_BASIS;
  }

  /// @inheritdoc IL2Deposit
  function sweep() public payable nonReentrant {
    // Verify the caller is whitelisted
    if (!allowedBridgeSweepers[msg.sender]) {
      revert ConnextErrors.UnauthorizedBridgeSweeper();
    }

    // Get the balance of nextUSDC in the contract
    uint256 balance = collateralToken.balanceOf(address(this));

    // If there is no balance, return
    if (balance == 0) {
      revert ConnextErrors.InvalidZeroOutput();
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
      0, // Asset is already nextUSDC, so no slippage will be incurred
      bridgeCallData
    );

    // send collected bridge fee to owner
    _recoverBridgeFee();

    // Emit the event
    emit ConnextEvents.BridgeSwept(bridgeDestinationDomain, bridgeTargetAddress, msg.sender, balance);
  }

  /// @inheritdoc IL2Deposit
  function setAllowedBridgeSweeper(address _sweeper, bool _allowed) external onlyOwner {
    allowedBridgeSweepers[_sweeper] = _allowed;
    emit ConnextEvents.BridgeSweeperAddressUpdated(_sweeper, _allowed);
  }

  /// @inheritdoc IL2Deposit
  function recoverNative(uint256 _amount, address _to) external onlyOwner {
    payable(_to).transfer(_amount);
  }

  /// @inheritdoc IL2Deposit
  function recoverERC20(address _token, uint256 _amount, address _to) external onlyOwner {
    IERC20(_token).safeTransfer(_to, _amount);
  }

  /// @inheritdoc IL2Deposit
  function setRate(uint256 _rate) external onlyOwner {
    emit ConnextEvents.RateUpdated(rate, _rate);
    rate = _rate;
  }

  /// @inheritdoc IL2Deposit
  function updateBridgeFeeShare(uint256 _newShare) external onlyOwner {
    if (_newShare > 100) revert ConnextErrors.InvalidBridgeFeeShare(_newShare);
    emit ConnextEvents.BridgeFeeShareUpdated(bridgeFeeShare, _newShare);
    bridgeFeeShare = _newShare;
  }

  /// @inheritdoc IL2Deposit
  function updateSweepBatchSize(uint256 _newBatchSize) external onlyOwner {
    if (_newBatchSize < 1e6) revert ConnextErrors.InvalidSweepBatchSize(_newBatchSize);
    emit ConnextEvents.SweepBatchSizeUpdated(sweepBatchSize, _newBatchSize);
    sweepBatchSize = _newBatchSize;
  }

  /**
   * @notice  Internal function to trade deposit tokens for nextUSDC and mint xZAI
   * @dev     Deposit Tokens should be available in the contract before calling this function
   * @param   _amountIn  Amount of tokens deposited
   * @param   _minOut  Minimum number of xZAI to accept to ensure slippage minimums
   * @param   _deadline  latest timestamp to accept this transaction
   * @return  uint256  Amount of xZAI minted to calling account
   */
  function _deposit(uint256 _amountIn, uint256 _minOut, uint256 _deadline) internal returns (uint256) {
    // calculate bridgeFee for deposit amount
    uint256 bridgeFee = getBridgeFeeShare(_amountIn);

    // subtract from _amountIn and add to bridgeFeeCollected
    _amountIn -= bridgeFee;
    bridgeFeeCollected += bridgeFee;

    // Trade deposit tokens for nextUSDC
    uint256 amountOut = _trade(_amountIn, _deadline);
    if (amountOut == 0) {
      revert ConnextErrors.InvalidZeroOutput();
    }

    // Calculate the amount of xZAI to mint
    uint256 xZAIAmount = (1e18 * amountOut) / rate;

    // Check that the user will get the minimum amount of xZAI
    if (xZAIAmount < _minOut) {
      revert ConnextErrors.InsufficientOutputAmount();
    }

    // Mint xZAI to the user
    IXERC20(address(xZAI)).mint(msg.sender, xZAIAmount);

    // Emit the event and return amount minted
    emit ConnextEvents.Deposit(msg.sender, _amountIn, xZAIAmount);
    return xZAIAmount;
  }

  /**
   * @notice  Trades deposit asset for nextUSDC
   * @dev     Note that min out is not enforced here since the asset will be priced to ZAI by the calling function
   * @param   _amountIn  Amount of deposit tokens to trade for collateral asset
   * @return  _deadline Deadline for the trade to prevent stale requests
   */
  function _trade(uint256 _amountIn, uint256 _deadline) internal returns (uint256) {
    // Approve the deposit asset to the connext contract
    depositToken.safeIncreaseAllowance(address(connext), _amountIn);

    // We will accept any amount of tokens out here... The caller of this function should verify the amount meets
    // minimums
    uint256 minOut = 0;

    // Swap the tokens
    uint256 amountNextUSDC =
      connext.swapExact(swapKey, _amountIn, address(depositToken), address(collateralToken), minOut, _deadline);

    // Subtract the bridge router fee
    if (bridgeRouterFeeBps > 0) {
      uint256 fee = (amountNextUSDC * bridgeRouterFeeBps) / 10_000;
      amountNextUSDC -= fee;
    }

    return amountNextUSDC;
  }

  /**
   * @notice This function transfer the bridge fee to the owner
   */
  function _recoverBridgeFee() internal {
    uint256 feeCollected = bridgeFeeCollected;
    bridgeFeeCollected = 0;
    // transfer collected fee to owner
    uint256 chainId;
    assembly {
      chainId := chainid()
    }

    IERC20(address(depositToken)).safeTransfer(owner(), feeCollected);
    emit ConnextEvents.SweeperBridgeFeeCollected(owner(), feeCollected);
  }
}
