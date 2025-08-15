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

import {IERC4626} from "../interfaces/vault/IERC4626.sol";
import {IPegStabilityModule, ZapSafetyPool} from "../periphery/zaps/implementations/ethereum/ZapSafetyPool.sol";
import {Ownable2StepUpgradeable} from "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {console} from "lib/forge-std/src/console.sol";

interface StableSwap {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
  function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
  function get_dx(int128 i, int128 j, uint256 dy) external view returns (uint256);
}

contract USDCVault is ERC20Upgradeable, Ownable2StepUpgradeable, IERC4626 {
  using SafeERC20 for IERC20;

  // State variables for different tokens, vaults, and external contracts
  IERC20 public USDC; // USDC token
  IERC20 public USDE; // USDe token
  IERC4626 public SZAI; // SZAI vault interface
  IERC4626 public SUSDE; // SUSDe vault interface
  IPegStabilityModule public PSM; // Peg Stability Module (for USDC-to-USDe conversion)
  ZapSafetyPool public zapContract; // Zap contract for interacting with safety pool
  StableSwap public stableSwap; // StableSwap interface for exchanging assets between pools

  /**
   * @dev Initializes the contract with necessary addresses and configurations.
   * @param _name The name of the vault token.
   * @param _symbol The symbol of the vault token.
   * @param _usdc The address of the USDC token contract.
   * @param _usde The address of the USDe token contract.
   * @param _sZAI The address of the SZAI vault contract.
   * @param _sUSDe The address of the SUSDe vault contract.
   * @param _psm The address of the Peg Stability Module (PSM).
   * @param _zapContract The address of the ZapSafetyPool contract.
   * @param _stableSwapPool The address of the StableSwap contract.
   */
  function initialize(
    string memory _name,
    string memory _symbol,
    address _usdc,
    address _usde,
    address _sZAI,
    address _sUSDe,
    address _psm,
    address _zapContract,
    address _stableSwapPool
  ) external initializer {
    USDC = IERC20(_usdc);
    USDE = IERC20(_usde);
    SZAI = IERC4626(_sZAI);
    SUSDE = IERC4626(_sUSDe);
    PSM = IPegStabilityModule(_psm);
    zapContract = ZapSafetyPool(_zapContract);
    stableSwap = StableSwap(_stableSwapPool);
    __Ownable_init(msg.sender);
    __ERC20_init(_name, _symbol);
  }

  /**
   * @dev Deposits the given amount of USDC into the vault, swaps for USDe, deposits it into the SUSDe vault,
   * then zaps into SZAI and mints shares for the receiver.
   * @param assets The amount of USDC to deposit.
   * @param receiver The address that will receive the minted shares.
   * @return shares The amount of shares minted and assigned to the receiver.
   */
  function deposit(uint256 assets, address receiver) external returns (uint256) {
    // 1. Take the USDC from the User as collateral
    USDC.safeTransferFrom(msg.sender, address(this), assets);

    // 2. Convert USDC to USDe
    uint256 balanceUSDe = _swapUSDCtoUSDe(assets);
    console.log("USDe balance this contract have after swap", balanceUSDe);

    // 3. Deposit the USDe into SUSDe Vault
    USDE.approve(address(SUSDE), balanceUSDe);
    uint256 susdeShares = SUSDE.deposit(balanceUSDe, address(this));
    console.log("After depositing in sUSDe vault get shares", susdeShares);
    // 4. Zap into SZAI from SUSDe shares
    uint256 SZAIBalanceBefore = IERC20(address(SZAI)).balanceOf(address(this)); // Before Zap
    IERC20(address(SUSDE)).approve(address(zapContract), susdeShares);
    zapContract.zapIntoSafetyPool(PSM, susdeShares);
    uint256 SZAIBalanceAfter = IERC20(address(SZAI)).balanceOf(address(this)); // After Zap
    console.log("After Zap we get SZAI", SZAIBalanceAfter);
    require(SZAIBalanceAfter > SZAIBalanceBefore, "Zap Failed");

    uint256 sZAIMinted = SZAIBalanceAfter - SZAIBalanceBefore;

    console.log("SZAI Minted : ", sZAIMinted);
    // 5. Calculate the number of shares to mint for the receiver based on the assets
    uint256 sharesToMint = previewDeposit(sZAIMinted);

    console.log("Shares to Mint", sharesToMint);

    // 6. Mint the calculated number of shares to the receiver
    _mint(receiver, sharesToMint);

    return sharesToMint;
  }

  /**
   * @dev Withdraws assets (SZAI) from the vault by burning the user's shares.
   * @param assets The amount of assets (SZAI) to withdraw.
   * @param receiver The address to receive the withdrawn assets.
   * @param owner The owner of the shares to burn.
   * @return shares The amount of shares burned.
   */
  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
    // 1. Calculate the number of shares the user needs to burn to withdraw the requested assets (SZAI)
    shares = previewWithdraw(assets);
    console.log("Shares to Burn", shares);

    // 3. Check if the vault has enough SZAI for the withdrawal
    uint256 vaultSZAI = IERC20(address(SZAI)).balanceOf(address(this));
    console.log("SZAI Balance in Vault: ", vaultSZAI);
    require(vaultSZAI >= assets, "Insufficient SZAI in vault for withdrawal");

    // 4. Transfer the SZAI to the receiver
    IERC20(address(SZAI)).safeTransfer(receiver, shares);

    // 5. Burn the shares from the owner's balance
    _burn(owner, assets);

    return shares; // Return the number of shares burned
  }
  /**
   * @dev Converts a given amount of assets into the equivalent number of shares.
   * @param assets The amount of assets to convert.
   * @return shares The equivalent number of shares.
   */

  function previewDeposit(
    uint256 assets
  ) public view returns (uint256 shares) {
    return _convertSZAIToUSDC(assets);
  }

  function previewWithdraw(
    uint256 assets
  ) public view returns (uint256 shares) {
    return _convertUSDCToSZAI(assets);
  }

  /**
   * @dev Returns the address of the asset held by the vault (USDC in this case).
   * @return The address of the asset.
   */
  function asset() external view returns (address) {
    return address(USDC);
  }

  function _convertSZAIToUSDC(
    uint256 assets
  ) internal view returns (uint256) {
    int128 indexTokenIn = 1; // USDC
    int128 indexTokenOut = 0; // USDe
    uint256 SzaiBalance = IERC20(address(SZAI)).balanceOf(address(this));
    console.log("SZAI Balance in contract", SzaiBalance);
    // convert SZAI to ZAI First
    uint256 ZaiBalance = SZAI.previewWithdraw(SzaiBalance);
    console.log("ZAI Assets", ZaiBalance);
    // Convert ZAI to SUSDe
    uint256 sUsdeBalance = PSM.toCollateralAmount(ZaiBalance);
    console.log("SUSDE Balance", sUsdeBalance);
    // Convert SUSDE to USDe
    uint256 usdeBalance = SUSDE.previewWithdraw(sUsdeBalance);
    console.log("USDE Balance", usdeBalance);
    // Convert USDE to USDC
    uint256 usdcBalance = stableSwap.get_dx(indexTokenIn, indexTokenOut, usdeBalance);
    return usdcBalance;
  }

  function _convertUSDCToSZAI(
    uint256 shares
  ) internal view returns (uint256) {
    int128 indexTokenIn = 1; // USDC
    int128 indexTokenOut = 0; // USDe
    // USDC to USDe
    uint256 usdeAfterSwap = stableSwap.get_dy(indexTokenIn, indexTokenOut, shares);
    console.log("USDE Swap Balance", usdeAfterSwap);
    // USDe to SUSDe
    uint256 susdeAfterDeposit = SUSDE.previewDeposit(usdeAfterSwap);
    console.log("SUSDE shares after deposit", susdeAfterDeposit);
    // Call PSM to get the ZAI Mint Amount
    uint256 zaiToMint = PSM.mintAmountIn(susdeAfterDeposit);
    console.log("ZAI to mint", zaiToMint);
    // Call preview deposit to get SZAI
    uint256 sZaiAfterDeposit = SZAI.previewDeposit(zaiToMint);
    console.log("SZAI After Deposit", sZaiAfterDeposit);
    return sZaiAfterDeposit;
  }

  /**
   * @dev Swaps USDC for USDe using the StableSwap contract.
   * @param _amount The amount of USDC to swap.
   * @return The amount of USDe obtained from the swap.
   */
  function _swapUSDCtoUSDe(
    uint256 _amount
  ) internal returns (uint256) {
    int128 indexTokenIn = 1; // USDC
    int128 indexTokenOut = 0; // USDe
    // Approve Curve Pool to use USDC
    USDC.approve(address(stableSwap), _amount);
    uint256 beforeBalanceUSDE = USDE.balanceOf(address(this)); // Before Balance
    StableSwap(stableSwap).exchange(indexTokenIn, indexTokenOut, _amount, 1);
    uint256 afterBalanceUSDE = USDE.balanceOf(address(this)); // After Balance
    require(afterBalanceUSDE > beforeBalanceUSDE, "Swap Failed");
    USDE.approve(address(SUSDE), afterBalanceUSDE);
    return afterBalanceUSDE;
  }
}
