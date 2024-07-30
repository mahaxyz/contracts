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

import "../../../lib/forge-std/src/console.sol";
import {IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";
import {ICurveStableSwapNG} from "../../interfaces/periphery/ICurveStableSwapNG.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface ICurveRouter {
  function add_liquidity(
    address _pool,
    uint256[3] memory _deposit_amounts,
    uint256 _min_mint_amount
  ) external returns (uint256);
}

/**
 * @title ZapCurvePool
 * @dev This contract allows users to perform a Zap operation by swapping collateral for zai tokens, adding liquidity to
 * curve LP, and staking the LP tokens.
 */
contract ZapCurvePool {
  IERC4626 public staking;

  ICurveStableSwapNG public pool;

  ICurveRouter public router;

  IERC20Metadata public zai;

  IERC20Metadata public collateral;

  IPegStabilityModule public psm;

  uint256 public decimalOffset;

  address private me;

  error OdosSwapFailed();
  error CollateralTransferFailed();
  error ZaiTransferFailed();

  event Zapped(
    address indexed user, uint256 indexed collateralAmount, uint256 indexed zaiAmount, uint256 newStakedAmount
  );

  /**
   * @dev Initializes the contract with the required contracts
   */
  constructor(address _staking, address _psm, address _router) {
    staking = IERC4626(_staking);
    psm = IPegStabilityModule(_psm);
    router = ICurveRouter(_router);

    pool = ICurveStableSwapNG(staking.asset());
    zai = IERC20Metadata(address(psm.zai()));
    collateral = IERC20Metadata(address(psm.collateral()));

    decimalOffset = 10 ** (18 - collateral.decimals());

    // give approvals
    zai.approve(address(_router), type(uint256).max);
    collateral.approve(address(_router), type(uint256).max);
    collateral.approve(address(psm), type(uint256).max);
    pool.approve(_staking, type(uint256).max);

    me = address(this);
  }

  /**
   * @notice Zaps collateral into ZAI LP tokens
   * @dev This function is used when the user only has collateral tokens.
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapIntoLP(uint256 collateralAmount, uint256 minLpAmount) external {
    // fetch tokens
    collateral.transferFrom(msg.sender, me, collateralAmount);

    // convert 50% collateral for zai
    uint256 zaiAmount = collateralAmount * decimalOffset / 2;
    psm.mint(address(this), zaiAmount);

    // add liquidity
    uint256[3] memory amounts;
    amounts[0] = zaiAmount;
    amounts[2] = collateralAmount / 2;

    router.add_liquidity(address(pool), amounts, minLpAmount);

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    sweep();

    emit Zapped(msg.sender, collateralAmount / 2, zaiAmount, pool.balanceOf(msg.sender));
  }

  /**
   * @notice Zaps ZAI and collateral into LP tokens
   * @dev This function is used when the user already has ZAI tokens.
   * @param zaiAmount The amount of ZAI to zap
   * @param collateralAmount The amount of collateral to zap
   * @param minLpAmount The minimum amount of LP tokens to stake
   */
  function zapWithZaiIntoLP(uint256 zaiAmount, uint256 collateralAmount, uint256 minLpAmount) external {
    // fetch tokens
    if (zaiAmount > 0) zai.transferFrom(msg.sender, me, zaiAmount);
    if (collateralAmount > 0) collateral.transferFrom(msg.sender, me, collateralAmount);

    // add liquidity
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = zaiAmount;
    amounts[1] = collateralAmount;
    pool.add_liquidity(amounts, minLpAmount, address(this));

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(pool.balanceOf(address(this)), msg.sender);

    // sweep any dust
    sweep();

    emit Zapped(msg.sender, collateralAmount, zaiAmount, pool.balanceOf(msg.sender));
  }

  function sweep() public {
    uint256 zaiB = zai.balanceOf(address(this));
    uint256 collateralB = collateral.balanceOf(address(this));

    if (zaiB > 0 && !zai.transfer(msg.sender, zaiB)) {
      revert ZaiTransferFailed();
    }

    if (collateralB > 0 && !collateral.transfer(msg.sender, collateralB)) {
      revert CollateralTransferFailed();
    }
  }
}
