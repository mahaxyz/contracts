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

import {IERC20, IPegStabilityModule} from "../../interfaces/core/IPegStabilityModule.sol";
import {ILocker} from "../../interfaces/governance/ILocker.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/**
 * @title ZapLockerLP
 * @dev This contract allows users to perform a Zap operation by swapping usdc for zai tokens, adding liquidity to curve
 * LP, and staking LP
 * tokens.
 */
contract ZapUSDCZAICuve {
  address public odos;
  IERC4626 public staking;
  IERC20 public zai;
  IERC20 public usdc;
  IERC20 public lp;
  IPegStabilityModule public psm;

  address private me;

  error OdosSwapFailed();
  error USDCTransferFailed();
  error ZaiTransferFailed();

  /**
   * @dev Initializes the contract with the required contracts
   */
  constructor(address _odos, address _staking, address _zai, address _usdc, address _lp, address _psm) {
    odos = _odos;
    staking = IERC4626(_staking);
    zai = IERC20(_zai);
    usdc = IERC20(_usdc);
    lp = IERC20(_lp);
    psm = IPegStabilityModule(_psm);

    // give approvals
    zai.approve(_odos, type(uint256).max);
    usdc.approve(_odos, type(uint256).max);
    lp.approve(_staking, type(uint256).max);

    me = address(this);
  }

  function zapUsdcIntoLP(uint256 usdcAmount, bytes calldata odosSwapData) external {
    // fetch tokens
    usdc.transferFrom(msg.sender, me, usdcAmount);

    // convert 50% usdc for zai
    psm.mint(address(this), usdcAmount * 1e12 / 2);

    // add liquidity
    // odos should be able to swap into LP tokens directly.
    (bool success,) = odos.call(odosSwapData);
    if (!success) revert OdosSwapFailed();

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(lp.balanceOf(address(this)), msg.sender);

    // sweep any dust
    sweep();
  }

  function zapZaiUsdcIntoLP(uint256 zaiAmount, uint256 usdcAmount, bytes calldata odosSwapData) external {
    // fetch tokens
    if (zaiAmount > 0) zai.transferFrom(msg.sender, me, zaiAmount);
    if (usdcAmount > 0) usdc.transferFrom(msg.sender, me, usdcAmount);

    // add liquidity
    // odos should be able to swap into LP tokens directly.
    (bool success,) = odos.call(odosSwapData);
    if (!success) revert OdosSwapFailed();

    // we now have LP tokens; deposit into staking contract for the user
    staking.deposit(lp.balanceOf(address(this)), msg.sender);

    // sweep any dust
    sweep();
  }

  function sweep() public {
    uint256 zaiB = zai.balanceOf(address(this));
    uint256 usdcB = usdc.balanceOf(address(this));

    if (zaiB > 0 && !zai.transfer(msg.sender, zaiB)) {
      revert ZaiTransferFailed();
    }

    if (usdcB > 0 && !usdc.transfer(msg.sender, usdcB)) {
      revert USDCTransferFailed();
    }
  }
}
