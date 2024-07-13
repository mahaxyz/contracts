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

interface IZaiPermissioned {
    function burn(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);

    function burnWithGasCompensation(
        address _account,
        uint256 _amount
    ) external returns (bool);

    function enableTroveManager(address _troveManager) external;

    function mint(address _account, uint256 _amount) external;

    function mintWithGasCompensation(
        address _account,
        uint256 _amount
    ) external returns (bool);

    function returnFromPool(
        address _poolAddress,
        address _receiver,
        uint256 _amount
    ) external;

    function borrowerOperationsAddress() external view returns (address);

    function DEBT_GAS_COMPENSATION() external view returns (uint256);

    function factory() external view returns (address);

    function gasPool() external view returns (address);

    function sendToSP(address _sender, uint256 _amount) external;

    function stabilityPoolAddress() external view returns (address);

    function troveManager(address) external view returns (bool);
}
