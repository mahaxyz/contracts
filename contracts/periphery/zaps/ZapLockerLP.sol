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

pragma solidity 0.8.20;

import {ILocker} from "../../interfaces/ILocker.sol";
import {IERC20, IWETH} from "../../interfaces/IWETH.sol";

/**
 * @title ZapLockerLP
 * @dev This contract allows users to perform a Zap operation by swapping ETH for Zero tokens, adding liquidity to Nile LP, and locking LP tokens.
 */
contract ZapLockerLP {
    address public odos;
    ILocker public locker;
    IERC20 public zero;
    IWETH public weth;
    IERC20 public lp;
    address private me;

    error OdosSwapFailed();
    error EthSendFailed();
    error ZeroTransferFailed();

    /**
     * @dev Initializes the contract with required parameters.
     * @param _odos The address of the Odos Router contract.
     * @param _locker The address of the LP Token Locker contract.
     * @param _zero The address of the Zero Token contract.
     * @param _weth The address of WETH.
     */
    constructor(address _odos, address _locker, address _zero, address _weth) {
        odos = _odos;
        locker = ILocker(_locker);
        zero = IERC20(_zero);
        weth = IWETH(_weth);
        lp = locker.underlying();

        // give approvals
        weth.approve(odos, type(uint256).max);
        zero.approve(odos, type(uint256).max);
        lp.approve(_locker, type(uint256).max);

        me = address(this);
    }

    /**
     * @dev Executes the Zap operation by swapping ETH for Zero tokens, adding liquidity to Nile LP, and locking LP tokens.
     * @param duration The duration for which the LP tokens will be locked.
     * @param zeroAmount How much ZERO the user will pass into the LP token
     * @param wethAmount How much WETH the user will pass into the LP token
     * @param odosSwapData The data required for the Odos swap.
     */
    function zapAndStake(
        uint256 duration,
        uint256 zeroAmount,
        uint256 wethAmount,
        bytes calldata odosSwapData
    ) external payable {
        // fetch tokens and wrap eth
        if (msg.value > 0) weth.deposit{value: msg.value}();
        if (zeroAmount > 0) zero.transferFrom(msg.sender, me, zeroAmount);
        if (wethAmount > 0) weth.transferFrom(msg.sender, me, wethAmount);

        // odos should be able to swap into LP tokens directly.
        (bool success, ) = odos.call(odosSwapData);
        if (!success) revert OdosSwapFailed();

        // stake the LP tokens that we get back from odos
        uint256 lpTokens = lp.balanceOf(address(this));
        locker.createLockFor(lpTokens, duration, msg.sender, true);

        // sweep any dust
        sweep();
    }

    function sweep() public {
        uint256 eth = address(this).balance;
        uint256 zeroB = zero.balanceOf(address(this));
        uint256 wethB = weth.balanceOf(address(this));

        if (eth > 0) {
            (bool ethSendSuccess, ) = msg.sender.call{value: eth}("");
            if (!ethSendSuccess) revert EthSendFailed();
        }

        if (zeroB > 0 && !zero.transfer(msg.sender, zeroB))
            revert ZeroTransferFailed();

        if (wethB > 0 && !weth.transfer(msg.sender, wethB))
            revert EthSendFailed();
    }
}
