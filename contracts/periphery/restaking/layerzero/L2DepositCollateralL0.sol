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

import {IStablecoinOFT} from "../../../interfaces/periphery/IStablecoinOFT.sol";
import {IStargate} from "../../../interfaces/periphery/layerzero/IStargate.sol";

import {IOFT, MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author  maha.xyz
 * @title   L2DepositCollateralL0 Contract
 * @dev     Tokens are sent to this contract via deposit, zai is minted for the user,
 *          and funds are batched and bridged down to the L1 for depositing into the maha protocol.
 * @notice  Allows L2 minting of zai tokens in exchange for deposited assets
 */
contract L2DepositCollateralL0 is OwnableUpgradeable, ReentrancyGuardUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice The rate at which the deposit token is converted to OFT
  uint256 public rate;

  /// @notice The slippage allowed for the bridge
  uint256 public slippage;

  /// @notice The maximum slippage allowed for the bridge
  uint256 public immutable MAX_SLIPPAGE = 1e18; // 100%

  /// @notice The OFT token address
  IStablecoinOFT public oft;

  /// @notice The deposit token address - this is what users will deposit to mint the OFT
  IERC20 public depositToken;

  /// @notice The address of the stargate bridge
  IStargate public stargate;

  /// @notice The contract address where the bridge call should be sent on mainnet ETH
  address public bridgeTargetAddress;

  /// @notice The mapping of allowed addresses that can trigger the bridge function
  mapping(address => bool) public allowedBridgeSweepers;

  event Deposit(address from, uint256 amountIn, uint256 amountOut);
  event BridgeSwept(address bridgeTargetAddress, address caller, uint256 balance);

  function initialize(
    IStablecoinOFT _oft,
    IERC20 _depositToken,
    IStargate _stargate,
    address _bridgeTargetAddress,
    address _governance,
    uint256 _rate,
    uint256 _slippage
  ) public initializer {
    __Ownable_init(_governance);
    allowedBridgeSweepers[_governance] = true;
    bridgeTargetAddress = _bridgeTargetAddress;
    depositToken = _depositToken;
    oft = _oft;
    rate = _rate;
    slippage = _slippage;
    stargate = _stargate;
  }

  function deposit(uint256 _amountIn) external nonReentrant returns (uint256 amountOut) {
    require(_amountIn > 0, "invalid amount");

    depositToken.safeTransferFrom(msg.sender, address(this), _amountIn);

    // Calculate the amount of zai to mint
    amountOut = (1e18 * _amountIn) / rate;

    // Mint zai to the user
    oft.restakingMint(msg.sender, amountOut);

    // Emit the event and return amount minted
    emit Deposit(msg.sender, _amountIn, amountOut);
  }

  function sweep(uint256 amount) public payable nonReentrant {
    // Verify the caller is whitelisted
    require(allowedBridgeSweepers[msg.sender], "invalid sweeper");

    // Get the balance of depositToken in the contract
    uint256 balance = depositToken.balanceOf(address(this));
    require(balance > 0, "no balance");
    if (amount == 0) amount = balance;

    // Approve it to the stargate contract
    depositToken.safeIncreaseAllowance(address(stargate), balance);

    SendParam memory _sendParam = SendParam({
      dstEid: 30_101, // Destination endpoint ID. 30101 is the mainnet endpoint.
      to: 0x0, // Recipient address.
      amountLD: amount, // Amount to send in local decimals.
      minAmountLD: amount * slippage / MAX_SLIPPAGE, //  Minimum amount to send in local decimals.
      extraOptions: "", // Additional options supplied by the caller to be used in the LayerZero message.
      composeMsg: "", // The composed message for the send() operation.
      oftCmd: "" // The OFT command to be executed, unused in default OFT implementations.
    });
    MessagingFee memory _fee = MessagingFee(0, 0);

    stargate.sendToken(_sendParam, _fee, owner());

    emit BridgeSwept(bridgeTargetAddress, msg.sender, balance);
  }

  function setAllowedBridgeSweeper(address _sweeper, bool _allowed) external onlyOwner {
    allowedBridgeSweepers[_sweeper] = _allowed;
  }

  function recoverERC20(address _token, uint256 _amount, address _to) external onlyOwner {
    IERC20(_token).safeTransfer(_to, _amount);
  }

  function setRate(uint256 _rate) external onlyOwner {
    rate = _rate;
  }
}
