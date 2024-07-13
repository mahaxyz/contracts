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

import {OFT, ERC20} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20FlashMint} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IZaiStablecoin} from "../interfaces/IZaiStablecoin.sol";

/**
 * @title Zai Stablecoin "USDz"
 * @author maha.xyz
 * @notice Represents the ZAI stablecoin. It is minted either by governance or by troves.
 * @dev This is a OFT compatible token.
 */
contract ZaiStablecoin is
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
        address _layerZeroEndpoint,
        address _delegate
    )
        OFT("Zai Stablecoin", "USDz", _layerZeroEndpoint, _delegate)
        Ownable(msg.sender)
        ERC20Permit("Zai Stablecoin")
    {
        _mint(msg.sender, 1e18);
        _burn(msg.sender, 1e18);
        _grantRole(DEFAULT_ADMIN_ROLE, address(this));
    }

    function grantTroveRole(address _account) external onlyOwner {
        _grantRole(TROVE_ROLE, _account);
    }

    function revokeTroveRole(address _account) external onlyOwner {
        _revokeRole(TROVE_ROLE, _account);
    }

    function isTrove(address _account) external view returns (bool what) {
        what = hasRole(TROVE_ROLE, _account);
    }

    /// @inheritdoc IZaiStablecoin
    function mint(
        address _account,
        uint256 _amount
    ) external onlyRole(TROVE_ROLE) {
        _mint(_account, _amount);
    }

    /// @inheritdoc IZaiStablecoin
    function burn(
        address _account,
        uint256 _amount
    ) external onlyRole(TROVE_ROLE) {
        _burn(_account, _amount);
    }

    /// @inheritdoc IZaiStablecoin
    function transferPermissioned(
        address _from,
        address _to,
        uint256 _amount
    ) external onlyRole(TROVE_ROLE) {
        _transfer(_from, _to, _amount);
    }
}
