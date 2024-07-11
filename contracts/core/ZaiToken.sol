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

pragma solidity 0.8.19;

import {OFT, IERC20, ERC20} from "@layerzerolabs/solidity-examples/contracts/token/oft/OFT.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {IZaiStablecoin} from "../interfaces/IZaiStablecoin.sol";

/**
 * @title Zai Stablecoin "USDz"
 * @author Maha.xyz
 * @notice Represents the ZAI stablecoin. It is minted either by governance or by troves.
 * @dev This is a OFT compatible token.
 */
contract ZaiStablecoin is
    IERC20,
    ERC20FlashMint,
    ERC20Permit,
    OFT,
    AccessControlEnumerable,
    IZaiStablecoin
{
    bytes32 public TROVE_ROLE = keccak256("TROVE_ROLE");

    /**
     * Initializes the stablecoin and sets the LZ endpoint
     * @param _layerZeroEndpoint the layerzero endpoint
     */
    constructor(
        address _layerZeroEndpoint
    )
        OFT("Zai Stablecoin", "USDz", _layerZeroEndpoint)
        ERC20Permit("Zai Stablecoin")
    {
        _mint(msg.sender, 1e18);
        _burn(msg.sender, 1e18);
        _grantRole(msg.sender, DEFAULT_ADMIN_ROLE);
    }

    /// @inheritdoc
    function mint(
        address _account,
        uint256 _amount
    ) external onlyRole(TROVE_ROLE) {
        _mint(_account, _amount);
    }

    /// @inheritdoc
    function burn(
        address _account,
        uint256 _amount
    ) external onlyRole(TROVE_ROLE) {
        _burn(_account, _amount);
    }
}
