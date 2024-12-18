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

interface StableSwap {
  function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;
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
    uint256 balanceUSDC = USDC.balanceOf(address(this));
    require(balanceUSDC > 0, "No USDC");

    uint256 balanceUSDe = _swapUSDCtoUSDe(balanceUSDC);

    // 3. Deposit the USDe into SUSDe Vault
    USDE.approve(address(SUSDE), balanceUSDe);
    uint256 susdeShares = SUSDE.deposit(balanceUSDe, address(this));

    // 4. Zap into SZAI from SUSDe shares
    uint256 SZAIBalanceBefore = IERC20(address(SZAI)).balanceOf(address(this)); // Before Zap
    IERC20(address(SUSDE)).approve(address(zapContract), susdeShares);
    zapContract.zapIntoSafetyPool(PSM, susdeShares);
    uint256 SZAIBalanceAfter = IERC20(address(SZAI)).balanceOf(address(this)); // After Zap

    require(SZAIBalanceAfter > SZAIBalanceBefore, "Zap Failed");

    // 5. Calculate the number of shares to mint for the receiver based on the assets
    uint256 sharesToMint = convertToShares(SZAIBalanceAfter - SZAIBalanceBefore);

    // 6. Mint the calculated number of shares to the receiver
    _mint(receiver, sharesToMint);

    return sharesToMint;
  }

  /**
   * @dev Mints new shares for the receiver (not implemented in this contract).
   * @param shares The number of shares to mint.
   * @param receiver The address that will receive the minted shares.
   * @return assets The number of assets corresponding to the minted shares.
   */
  function mint(uint256 shares, address receiver) external returns (uint256 assets) {}

  /**
   * @dev Withdraws assets (SZAI) from the vault by burning the user's shares.
   * @param assets The amount of assets (SZAI) to withdraw.
   * @param receiver The address to receive the withdrawn assets.
   * @param owner The owner of the shares to burn.
   * @return shares The amount of shares burned.
   */
  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {
    // 1. Calculate the number of shares the user needs to burn to withdraw the requested assets (SZAI)
    shares = convertToShares(assets);

    // 2. Ensure the owner has enough shares to burn
    uint256 ownerShares = balanceOf(owner);
    require(ownerShares >= shares, "Insufficient shares to withdraw");

    // 3. Check if the vault has enough SZAI for the withdrawal
    uint256 vaultSZAI = IERC20(address(SZAI)).balanceOf(address(this));
    require(vaultSZAI >= assets, "Insufficient SZAI in vault for withdrawal");

    // 4. Transfer the SZAI to the receiver
    IERC20(address(SZAI)).safeTransfer(receiver, assets);

    // 5. Burn the shares from the owner's balance
    _burn(owner, shares);

    return shares; // Return the number of shares burned
  }

  /**
   * @dev Allows for the redemption of shares for assets (not implemented in this contract).
   * @param shares The number of shares to redeem.
   * @param receiver The address to receive the redeemed assets.
   * @param owner The owner of the shares to redeem.
   * @return assets The amount of assets redeemed.
   */
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {}

  /**
   * @dev Converts a given amount of assets into the equivalent number of shares.
   * @param assets The amount of assets to convert.
   * @return shares The equivalent number of shares.
   */
  function convertToShares(
    uint256 assets
  ) public view returns (uint256 shares) {
    uint256 totalAssetsInVault = totalAssets(); // The total assets held by the vault (SZAI)
    uint256 totalSupplyVault = totalSupply(); // The total number of shares in circulation

    // Handle the edge case where no shares exist (empty vault)
    if (totalAssetsInVault == 0 || totalSupplyVault == 0) {
      // If the vault is empty, the first deposit should mint exactly the number of shares as the amount of assets
      return assets;
    }

    // Convert assets to shares (based on the ratio of totalAssets / totalSupply)
    return (assets * totalSupplyVault) / totalAssetsInVault;
  }

  /**
   * @dev Converts a given number of shares into the equivalent amount of assets.
   * @param shares The number of shares to convert.
   * @return assets The equivalent amount of assets.
   */
  function convertToAssets(
    uint256 shares
  ) public view returns (uint256 assets) {
    uint256 totalAssetsInVault = totalAssets(); // The total assets held by the vault (SZAI)
    uint256 totalSupplyVault = totalSupply(); // The total number of shares in circulation

    // Handle the edge case where no shares exist (empty vault)
    if (totalAssetsInVault == 0 || totalSupplyVault == 0) {
      // If the vault is empty, the first deposit should mint exactly the number of shares as the amount of assets
      return shares;
    }

    // Convert shares to assets (based on the ratio of totalAssets / totalSupply)
    return (shares * totalAssetsInVault) / totalSupplyVault;
  }

  /**
   * @dev Returns the address of the asset held by the vault (USDC in this case).
   * @return The address of the asset.
   */
  function asset() external view returns (address) {
    return address(USDC);
  }

  /**
   * @dev Returns the total assets held by the vault (SZAI).
   * @return The total assets in the vault.
   */
  function totalAssets() public view returns (uint256) {
    return IERC20(address(SZAI)).balanceOf(address(this));
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
