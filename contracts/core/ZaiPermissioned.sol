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

import {IERC3156FlashBorrower} from "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IZaiCore} from "../interfaces/IZaiCore.sol";
import {IZaiStablecoin} from "../interfaces/IZaiStablecoin.sol";
import {IZaiPermissioned} from "../interfaces/IZaiPermissioned.sol";

/**
 * @title Permissioned Zai minter
 * @author maha.xyz
 * @notice CDP minted against collateral deposits within `TroveManager`.
 * This contract has a 1:n relationship with multiple deployments of `TroveManager`,
 * each of which hold one collateral type which may be used to mint this token.
 */
contract ZaiPermissioned is IZaiPermissioned {
    /// @inheritdoc IZaiPermissioned
    IZaiStablecoin public immutable zai;

    /// @inheritdoc IZaiPermissioned
    address public immutable stabilityPoolAddress;

    /// @inheritdoc IZaiPermissioned
    address public immutable borrowerOperationsAddress;

    /// @inheritdoc IZaiPermissioned
    address public immutable factory;

    /// @inheritdoc IZaiPermissioned
    address public immutable gasPool;

    /// @inheritdoc IZaiPermissioned
    mapping(address => bool) public troveManager;

    // Amount of debt to be locked in gas pool on opening troves
    /// @inheritdoc IZaiPermissioned
    uint256 public immutable DEBT_GAS_COMPENSATION;

    constructor(
        address _zai,
        address _stabilityPoolAddress,
        address _borrowerOperationsAddress,
        address _factory,
        address _gasPool,
        uint256 _gasCompensation
    ) {
        zai = IZaiStablecoin(_zai);
        stabilityPoolAddress = _stabilityPoolAddress;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        factory = _factory;
        gasPool = _gasPool;

        DEBT_GAS_COMPENSATION = _gasCompensation;
    }

    /// @inheritdoc IZaiPermissioned
    function enableTroveManager(address _troveManager) external {
        require(msg.sender == factory, "!Factory");
        troveManager[_troveManager] = true;
    }

    // --- Functions for intra-Zai calls ---

    /// @inheritdoc IZaiPermissioned
    function mintWithGasCompensation(
        address _account,
        uint256 _amount
    ) external returns (bool) {
        require(msg.sender == borrowerOperationsAddress);
        zai.mint(_account, _amount);
        zai.mint(gasPool, DEBT_GAS_COMPENSATION);
        return true;
    }

    /// @inheritdoc IZaiPermissioned
    function burnWithGasCompensation(
        address _account,
        uint256 _amount
    ) external returns (bool) {
        require(msg.sender == borrowerOperationsAddress);
        zai.burn(_account, _amount);
        zai.burn(gasPool, DEBT_GAS_COMPENSATION);
        return true;
    }

    /// @inheritdoc IZaiPermissioned
    function mint(address _account, uint256 _amount) external {
        require(
            msg.sender == borrowerOperationsAddress || troveManager[msg.sender],
            "Debt: Caller not BO/TM"
        );
        zai.mint(_account, _amount);
    }

    /// @inheritdoc IZaiPermissioned
    function balanceOf(address _account) external view returns (uint256) {
        return zai.balanceOf(_account);
    }

    /// @inheritdoc IZaiPermissioned
    function burn(address _account, uint256 _amount) external {
        require(troveManager[msg.sender], "Debt: Caller not TroveManager");
        zai.burn(_account, _amount);
    }

    /// @inheritdoc IZaiPermissioned
    function sendToSP(address _sender, uint256 _amount) external {
        require(
            msg.sender == stabilityPoolAddress,
            "Debt: Caller not StabilityPool"
        );
        zai.transferPermissioned(_sender, msg.sender, _amount);
    }

    /// @inheritdoc IZaiPermissioned
    function returnFromPool(
        address _poolAddress,
        address _receiver,
        uint256 _amount
    ) external {
        require(
            msg.sender == stabilityPoolAddress || troveManager[msg.sender],
            "Debt: Caller not TM/SP"
        );
        zai.transferPermissioned(_poolAddress, _receiver, _amount);
    }
}
