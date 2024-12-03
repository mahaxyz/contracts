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

import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IOFT} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BaseBridgeCron is AccessControlEnumerable {
  using SafeERC20 for IERC20;

  bytes32 public immutable EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
  IOFT public immutable OFT_ADAPTER;
  IERC20 public immutable ZAI;

  address public remoteDestination;
  uint32 public remoteEID;

  constructor(address _ZAI, address _adapter) {
    ZAI = IERC20(_ZAI);
    OFT_ADAPTER = IOFT(_adapter);
    ZAI.approve(address(OFT_ADAPTER), type(uint256).max);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXECUTOR_ROLE, msg.sender);
  }

  function execute() public payable onlyRole(EXECUTOR_ROLE) {
    uint256 amountsZAI = ZAI.balanceOf(address(this));
    _bridgeToBase(amountsZAI);
  }

  /**
   * @notice Sets the destination addresses for cross-chain transfers.
   */
  function setDestinationAddresses(address _remoteAddr, uint32 _dstEID) external onlyRole(DEFAULT_ADMIN_ROLE) {
    remoteDestination = _remoteAddr;
    remoteEID = _dstEID;
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by owner of the contract
   * @param token The ERC20 token to be refunded.
   */
  function refund(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }

  /**
   * @notice Bridges the specified amount of ZAI to the remote chain.
   * @param _amount The amount of ZAI to be bridged.
   */
  function _bridgeToBase(uint256 _amount) internal {
    SendParam memory sendParam = SendParam({
      dstEid: remoteEID,
      to: _addressToBytes32(remoteDestination),
      amountLD: _amount,
      minAmountLD: _amount,
      extraOptions: new bytes(0),
      composeMsg: new bytes(0),
      oftCmd: ""
    });

    MessagingFee memory messagingFee = OFT_ADAPTER.quoteSend(sendParam, false);
    OFT_ADAPTER.send{value: messagingFee.nativeFee}(sendParam, messagingFee, address(this));
  }

  /**
   * @notice Converts an address to a bytes32 format.
   * @dev This is necessary for cross-chain transfers where addresses need to be converted to bytes32.
   * @param _addr The address to convert.
   * @return The converted bytes32 representation of the address.
   */
  function _addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }
}
