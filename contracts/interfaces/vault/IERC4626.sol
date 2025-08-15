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

interface IERC4626 {
  event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);
  event Withdraw(
    address indexed sender, address indexed receiver, address indexed owner, uint256 assets, uint256 shares
  );
  /**
   * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
   *
   * - MUST be an ERC-20 token contract.
   * - MUST NOT revert.
   */

  function asset() external view returns (address assetTokenAddress);
  //   /**
  //    * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
  //    * current on-chain conditions.
  //    *
  //    * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
  //    *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
  //    *   in the same transaction.
  //    * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
  //    *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
  //    * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
  //    * - MUST NOT revert.
  //    *
  //    * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
  //    * share price or some other type of condition, meaning the depositor will lose assets by depositing.
  //    */
  function previewDeposit(
    uint256 assets
  ) external view returns (uint256 shares);
  /**
   * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
   *
   * - MUST emit the Deposit event.
   * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
   *   deposit execution, and are accounted for during deposit.
   * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
   *   approving enough underlying tokens to the Vault contract, etc).
   *
   * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
   */
  function deposit(uint256 assets, address receiver) external returns (uint256 shares);
  //   /**
  //    * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
  //    * given current on-chain conditions.
  //    *
  //    * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a
  // withdraw
  //    *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
  //    *   called
  //    *   in the same transaction.
  //    * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
  //    *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
  //    * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
  //    * - MUST NOT revert.
  //    *
  //    * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
  //    * share price or some other type of condition, meaning the depositor will lose assets by depositing.
  //    */
  function previewWithdraw(
    uint256 assets
  ) external view returns (uint256 shares);
  //   /**
  //    * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
  //    *
  //    * - MUST emit the Withdraw event.
  //    * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
  //    *   withdraw execution, and are accounted for during withdraw.
  //    * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
  //    *   not having enough shares, etc).
  //    *
  //    * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
  //    * Those methods should be performed separately.
  //    */
  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);
}
