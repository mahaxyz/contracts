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

import {OwnableUpgradeable, Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {IStargate} from "@stargatefinance/stg-evm-v2/src/interfaces/IStargate.sol";
import {MessagingFee, OFTReceipt, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SUSDECollectorCron is Ownable2StepUpgradeable {
  using SafeERC20 for IERC20;
  /// @notice Address of the ODOS router for executing swaps.
  address public odos;

  /// @notice Address of the sUSDz token contract.
  address public sUSDz;

  /// @notice Interface for the USDC token contract.
  IERC20 public usdc;

  /// @notice Initializes the contract with addresses for the ODOS router, sUSDz, and USDC tokens.
  /// @param _odos Address of the ODOS router.
  /// @param _sUsde Address of the sUSDz token contract.
  /// @param _usdc Address of the USDC token contract.
  function initialize(
    address _odos,
    address _sUsde,
    address _usdc
  ) public initializer {
    __Ownable_init(msg.sender);
    sUSDz = _sUsde;
    usdc = IERC20(_usdc);
    setOdos(_odos);
  }

  function prepareTakeTaxi(
    address _stargate,
    uint32 _dstEid,
    uint256 _amount,
    address _receiver
  )
    external
    view
    returns (
      uint256 valueToSend,
      SendParam memory sendParam,
      MessagingFee memory messagingFee
    )
  {
    sendParam = SendParam({
      dstEid: _dstEid,
      to: addressToBytes32(_receiver),
      amountLD: _amount,
      minAmountLD: _amount,
      extraOptions: new bytes(0),
      composeMsg: new bytes(0),
      oftCmd: ""
    });

    IStargate stargate = IStargate(_stargate);

    (, , OFTReceipt memory receipt) = stargate.quoteOFT(sendParam);
    sendParam.minAmountLD = receipt.amountReceivedLD;

    messagingFee = stargate.quoteSend(sendParam, false);
    valueToSend = messagingFee.nativeFee;

    if (stargate.token() == address(0x0)) {
      valueToSend += sendParam.amountLD;
    }
  }

  /// @notice Executes a swap from sUSDz to USDC via the ODOS router.
  /// @dev This function can only be called by the contract owner.
  /// @param data Encoded data required by the ODOS router for executing the swap.
  function swapToUSDC(bytes calldata data) external onlyOwner {
    (bool ok, ) = odos.call(data);
    require(ok, "odos call failed");
  }

  /// @notice Sets the address for the ODOS router.
  /// @param _odos New address of the ODOS router.
  function setOdos(address _odos) public onlyOwner {
    odos = _odos;
  }

  function addressToBytes32(address _addr) internal pure returns (bytes32) {
    return bytes32(uint256(uint160(_addr)));
  }

  function distributeRevenue() internal {
    // 50 % to ZAI Vault SUSDZ stakers


    // 50% Bridge from ETH to Base using Stargate and
    
    // Call Odos to execute the buy back and burn on base.
  }
}
