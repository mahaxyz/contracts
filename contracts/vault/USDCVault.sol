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

  IERC20 public USDC;
  IERC20 public USDE;
  IERC4626 public SZAI;
  IERC4626 public SUSDE;
  IPegStabilityModule public PSM;
  ZapSafetyPool public zapContract;
  StableSwap public stableSwap;

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

  function deposit(uint256 assets, address receiver) external returns (uint256) {
    // 1. Take the USDC from the User as collateral
    USDC.safeTransferFrom(msg.sender, address(this), assets);
    // 2. Once we get the USDC do the conversion to get USDe
    uint256 balanceUSDC = USDC.balanceOf(address(this));
    require(balanceUSDC > 0, "No USDC");
    uint256 balanceUSDe = _swapUSDCtoUSDe(balanceUSDC);
    //3. Now use this USDe to deposit into SUSDe Vault
    uint256 shares = SUSDE.deposit(balanceUSDe, address(this));
    uint256 SZAIBalanceBefore = IERC20(address(SZAI)).balanceOf(address(this)); // Before Zap
    zapContract.zapIntoSafetyPool(PSM, shares);
    uint256 SZAIBalanceAfter = IERC20(address(SZAI)).balanceOf(address(this)); // After Zap
    require(SZAIBalanceAfter > SZAIBalanceBefore, "Zap Failed");
    shares = SZAIBalanceAfter - SZAIBalanceBefore;
    _mint(receiver, shares);
    return shares;
  }

  function mint(uint256 shares, address receiver) external returns (uint256) {
    // 1. Take USDC from the User as collateral
    USDC.safeTransferFrom(msg.sender, address(this), shares);
    uint256 balanceUSDC = USDC.balanceOf(address(this));
    require(balanceUSDC > 0, "No USDC");
    uint256 balanceUSDe = _swapUSDCtoUSDe(balanceUSDC);
    uint256 assets = SUSDE.mint(balanceUSDe, address(this));
    uint256 SZAIBalanceBefore = IERC20(address(SZAI)).balanceOf(address(this)); // Before Zap
    zapContract.zapIntoSafetyPool(PSM, assets);
    uint256 SZAIBalanceAfter = IERC20(address(SZAI)).balanceOf(address(this)); // After Zap
    require(SZAIBalanceAfter > SZAIBalanceBefore, "Zap Failed");
    assets = SZAIBalanceAfter - SZAIBalanceBefore;
    _mint(receiver, assets);
    return assets;
  }

  function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares) {}
  function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets) {}

  function asset() external view returns (address) {
    return address(USDC);
  }

  function totalAssets() external view returns (uint256) {
    return USDC.balanceOf(address(this));
  }
  //   function convertToAssets(
  //     uint256 shares
  //   ) external view returns (uint256 assets) {}
  //   function convertToShares(
  //     uint256 assets
  //   ) external view returns (uint256 shares) {}
  //   function maxMint(
  //     address receiver
  //   ) external view returns (uint256 maxShares) {}
  //   function maxRedeem(
  //     address owner
  //   ) external view returns (uint256 maxShares) {}
  //   function maxWithdraw(
  //     address owner
  //   ) external view returns (uint256 maxAssets) {}
  //   function previewDeposit(
  //     uint256 assets
  //   ) external view returns (uint256 shares) {}
  //   function previewMint(
  //     uint256 shares
  //   ) external view returns (uint256 assets) {}
  //   function previewRedeem(
  //     uint256 shares
  //   ) external view returns (uint256 assets) {}
  //   function previewWithdraw(
  //     uint256 assets
  //   ) external view returns (uint256 shares) {}
  //   function maxDeposit(
  //     address receiver
  //   ) external view returns (uint256 maxAssets) {}

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
    return afterBalanceUSDE;
  }
}
