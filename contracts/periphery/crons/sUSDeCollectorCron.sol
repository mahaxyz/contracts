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

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title sUSDeCollectorCron
 * @notice A contract that manages revenue distribution through USDC transfers, using Stargate for cross-chain messaging
 *         and optionally performing swaps via the ODOS router.
 * @dev The contract is upgradeable and inherits `Ownable2StepUpgradeable`. It supports setting an ODOS router,
 *      defining sZAI and USDC tokens, and has functions for swapping and cross-chain revenue distribution.
 */
contract sUSDeCollectorCron is AccessControlEnumerable {
  using SafeERC20 for IERC20;

  bytes32 public immutable EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
  address public immutable ODOS;
  IERC4626 public immutable SZAI;
  IERC20 public immutable ZAI;
  IERC20 public immutable SUSDE;

  address public treasury;
  address public mahaBuyback;
  address public mahaStakers;

  event RevenueDistributed(address indexed receiver, uint256 indexed amount);
  event RevenueCollected(uint256 indexed amount);

  constructor(address _odos, address _sZAI, address _sUSDe) {
    SZAI = IERC4626(_sZAI);
    SUSDE = IERC20(_sUSDe);
    ZAI = IERC20(SZAI.asset());
    ODOS = _odos;

    SUSDE.approve(ODOS, type(uint256).max);

    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(EXECUTOR_ROLE, msg.sender);
  }

  /**
   * @notice Executes a transaction on the ODOS router, distributing revenue to sZAI and MAHA stakers, and the treasury.
   * @param data The transaction data to be executed on the ODOS router.
   */
  function execute(bytes calldata data) public payable onlyRole(EXECUTOR_ROLE) {
    (bool ok,) = ODOS.call{value: msg.value}(data);
    require(ok, "odos call failed");

    uint256 balance = ZAI.balanceOf(address(this));
    emit RevenueCollected(balance);

    // send 70% to sZAI stakers
    uint256 amountsZAI = _calculatePercentage(balance, 7000);
    ZAI.transfer(address(SZAI), amountsZAI);
    emit RevenueDistributed(address(SZAI), amountsZAI);

    // send 12.5% to MAHA stakers
    uint256 amountsMAHA = _calculatePercentage(balance, 1250);
    ZAI.transfer(mahaStakers, amountsMAHA);
    emit RevenueDistributed(mahaStakers, amountsMAHA);

    // send 12.5% to Buyback and Burn
    uint256 amountsBuyback = _calculatePercentage(balance, 1250);
    ZAI.transfer(mahaBuyback, amountsMAHA);
    emit RevenueDistributed(mahaBuyback, amountsMAHA);

    // rest to treasury
    uint256 amountsTreasury = balance - amountsZAI - amountsMAHA - amountsBuyback;
    ZAI.transfer(treasury, amountsTreasury);
    emit RevenueDistributed(treasury, amountsTreasury);
  }

  /**
   * @notice Sets the destination addresses for cross-chain transfers.
   */
  function setDestinationAddresses(
    address _treasury,
    address _mahaStakers,
    address _mahaBuybacks
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    treasury = _treasury;
    mahaBuyback = _mahaBuybacks;
    mahaStakers = _mahaStakers;
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
   * @notice Calculates a percentage of a given `amount` based on basis points (bps).
   * @dev The calculation uses basis points, where 10,000 bps = 100%.
   *      Reverts if `amount * bps` is less than 10,000 to prevent overflow issues.
   * @param amount The initial amount to calculate the percentage from.
   * @param bps The basis points (bps) representing the percentage (e.g., 5000 for 50%).
   * @return The calculated percentage of `amount` based on `bps`.
   */
  function _calculatePercentage(uint256 amount, uint256 bps) internal pure returns (uint256) {
    require((amount * bps) >= 10_000, "amount * bps > 10_000");
    return (amount * bps) / 10_000;
  }
}
