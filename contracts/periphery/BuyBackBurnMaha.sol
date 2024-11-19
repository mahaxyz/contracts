// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.21;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title BuyBackBurnMaha
 * @dev This contract facilitates the buy-back and burning of MAHA tokens using USDC.
 *      It leverages a specified ODOS router for token swaps and allows only authorized
 *      distributors to perform buy-back and burn operations.
 */
contract BuyBackBurnMaha is AccessControlUpgradeable {
  using SafeERC20 for IERC20;

  /// @notice Role identifier for accounts authorized to initiate buy-back and burn operations.
  bytes32 public constant DISTRIBUTOR_ROLE = keccak256("DISTRIBUTOR_ROLE");

  /// @notice Address representing the burn address (tokens sent here are considered burned).
  address public constant DEAD_ADDRESS =
    0x0000000000000000000000000000000000000000;

  /// @notice Address of the ODOS router used for swapping USDC to MAHA.
  address public odos;

  /// @notice The MAHA token contract.
  IERC20 public maha;

  /// @notice The USDC token contract.
  IERC20 public usdc;

  /**
   * @notice Initializes the contract with MAHA and USDC token addresses, ODOS router address, and distributor role.
   * @param _maha Address of the MAHA token contract.
   * @param _usdc Address of the USDC token contract.
   * @param _odos Address of the ODOS router used for swaps.
   * @param _distributor Address to be assigned the DISTRIBUTOR_ROLE.
   */
  function initialize(
    address _maha,
    address _usdc,
    address _odos,
    address _distributor
  ) external initializer {
    __AccessControl_init();
    maha = IERC20(_maha);
    usdc = IERC20(_usdc);

    setOdos(_odos);
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(DISTRIBUTOR_ROLE, _distributor);
  }

  /**
   * @notice Updates the address of the ODOS router.
   * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
   * @param _newOdos New address of the ODOS router.
   */
  function setOdos(address _newOdos) public onlyRole(DEFAULT_ADMIN_ROLE) {
    odos = _newOdos;
  }

  /**
   * @notice Executes the buy-back and burn operation.
   * @dev Only callable by an account with the DISTRIBUTOR_ROLE.
   *      Swaps USDC for MAHA through the ODOS router and sends the MAHA to the burn address.
   * @param odosData Encoded data for the ODOS router call to perform the swap.
   * @param amount How much USDC you want ODOS router to swap
   */
  function buyMahaBurn(
    bytes calldata odosData,
    uint256 amount
  ) external payable onlyRole(DISTRIBUTOR_ROLE) {
    IERC20(usdc).approve(odos, amount);

    (bool ok, ) = odos.call{value: msg.value}(odosData);
    require(ok, "odos call failed");

    uint256 mahaBalanceAfterSwap = IERC20(maha).balanceOf(address(this));
    require(mahaBalanceAfterSwap > 0, "No Maha to burn!");

    // Transfer MAHA tokens to the dead address to effectively "burn" them.
    IERC20(maha).safeTransfer(DEAD_ADDRESS, mahaBalanceAfterSwap);
  }

  /**
   * @notice Refunds the specified token balance held by the contract to the caller.
   * @dev Only callable by an account with the DEFAULT_ADMIN_ROLE.
   * @param token The ERC20 token to be refunded.
   */
  function refund(IERC20 token) external onlyRole(DEFAULT_ADMIN_ROLE) {
    token.safeTransfer(msg.sender, token.balanceOf(address(this)));
  }
}
