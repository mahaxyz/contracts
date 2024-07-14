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

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title PSMEventsLib
 * @author maha.xyz
 * @notice This library defines events for the PSM contract
 */
library PSMEventsLib {
    /**
     * @notice Emitted when a user mints ZAI
     * @param destination Where the minted ZAI will be sent
     * @param shares The amount of ZAI minted
     * @param amount The amount of collateral taken
     * @param newDebt The current new debt of the PSM module
     * @param supplyCap The current supply cap of the PSM module
     * @param sender The address that called the mint function
     */
    event Mint(
        address indexed destination,
        uint256 indexed shares,
        uint256 indexed amount,
        uint256 newDebt,
        uint256 supplyCap,
        address sender
    );

    /**
     * @notice Emitted when the rate is updated
     * @dev Called by the admin
     * @param oldRate The old rate of ZAI/Collateral
     * @param newRate The new rate of ZAI/Collateral
     * @param sender The address that called the update function
     */
    event RateUpdated(
        uint256 indexed oldRate,
        uint256 indexed newRate,
        address sender
    );

    /**
     * @notice Emitted when a user redeems ZAI
     * @param destination Where the collateral will be sent
     * @param shares The amount of ZAI burnt
     * @param amount The amount of collateral taken out
     * @param newDebt The current new debt of the PSM module
     * @param supplyCap The current supply cap of the PSM module
     * @param sender The address that called the redeem function
     */
    event Redeem(
        address indexed destination,
        uint256 indexed shares,
        uint256 indexed amount,
        uint256 newDebt,
        uint256 supplyCap,
        address sender
    );

    /**
     * @notice Emitted when the supply cap is updated
     * @param _newSupplyCap The new supply cap
     * @param _newDebtCap The new debt cap
     * @param _oldSupplyCap The old supply cap
     * @param _oldDebtCap The old debt cap
     * @param sender The address that called the update function
     */
    event SupplyCapUpdated(
        uint256 indexed _newSupplyCap,
        uint256 indexed _newDebtCap,
        uint256 _oldSupplyCap,
        uint256 _oldDebtCap,
        address sender
    );
}
