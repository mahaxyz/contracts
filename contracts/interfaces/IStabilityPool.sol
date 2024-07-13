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

import {IZaiOwnable} from "./IZaiOwnable.sol";
import {IZaiPermissioned} from "./IZaiPermissioned.sol";
import {IZaiVault} from "./IZaiVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStabilityPool is IZaiOwnable {
    struct AccountDeposit {
        uint128 amount;
        uint128 timestamp; // timestamp of the last deposit
    }

    struct Snapshots {
        uint256 P;
        uint256 G;
        uint128 scale;
        uint128 epoch;
    }

    struct SunsetIndex {
        uint128 idx;
        uint128 expiry;
    }
    struct Queue {
        uint16 firstSunsetIndexKey;
        uint16 nextSunsetIndexKey;
    }

    function claimCollateralGains(
        address recipient,
        uint256[] calldata collateralIndexes
    ) external;

    function claimReward(address recipient) external returns (uint256 amount);

    function enableCollateral(IERC20 _collateral) external;

    function offset(
        address collateral,
        uint256 _debtToOffset,
        uint256 _collToAdd
    ) external;

    function provideToSP(uint256 _amount) external;

    function startCollateralSunset(IERC20 collateral) external;

    function vaultClaimReward(
        address claimant,
        address
    ) external returns (uint256 amount);

    function withdrawFromSP(uint256 _amount) external;

    function DECIMAL_PRECISION() external view returns (uint256);

    function P() external view returns (uint256);

    function SCALE_FACTOR() external view returns (uint256);

    function SUNSET_DURATION() external view returns (uint128);

    function accountDeposits(
        address
    ) external view returns (uint128 amount, uint128 timestamp);

    function claimableReward(
        address _depositor
    ) external view returns (uint256);

    function collateralGainsByDepositor(
        address depositor,
        uint256
    ) external view returns (uint80 gains);

    function collateralTokens(uint256) external view returns (IERC20);

    function currentEpoch() external view returns (uint128);

    function currentScale() external view returns (uint128);

    function debtToken() external view returns (IZaiPermissioned);

    function depositSnapshots(
        address
    )
        external
        view
        returns (uint256 P, uint256 G, uint128 scale, uint128 epoch);

    function depositSums(address, uint256) external view returns (uint256);

    function emissionId() external view returns (uint256);

    function epochToScaleToG(uint128, uint128) external view returns (uint256);

    /* collateral Gain sum 'S': During its lifetime, each deposit d_t earns a collateral gain of ( d_t * [S - S_t] )/P_t, where S_t
     * is the depositor's snapshot of S taken at the time t when the deposit was made.
     *
     * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
     *
     * - The inner mapping records the sum S at different scales
     * - The outer mapping records the (scale => sum) mappings, for different epochs.
     */
    // index values are mapped against the values within `collateralTokens`
    function epochToScaleToSums(
        uint128,
        uint128,
        uint256
    ) external view returns (uint256);

    function factory() external view returns (address);

    function getCompoundedDebtDeposit(
        address _depositor
    ) external view returns (uint256);

    function getDepositorCollateralGain(
        address _depositor
    ) external view returns (uint256[] memory collateralGains);

    /**
     * @notice Tracker for Debt held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalDebtTokenDeposits() external view returns (uint256);

    function getWeek() external view returns (uint256 week);

    function guardian() external view returns (address);

    function indexByCollateral(
        address collateral
    ) external view returns (uint256 index);

    function lastCollateralError_Offset() external view returns (uint256);

    function lastDebtLossError_Offset() external view returns (uint256);

    function lastZaiError() external view returns (uint256);

    function lastUpdate() external view returns (uint32);

    function liquidationManager() external view returns (address);

    function owner() external view returns (address);

    function periodFinish() external view returns (uint32);

    function rewardRate() external view returns (uint128);

    function vault() external view returns (IZaiVault);
}
