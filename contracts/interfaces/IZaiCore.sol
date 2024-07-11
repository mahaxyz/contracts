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

interface IZaiCore {
    event FeeReceiverSet(address feeReceiver);
    event GuardianSet(address guardian);
    event NewOwnerAccepted(address oldOwner, address owner);
    event NewOwnerCommitted(
        address owner,
        address pendingOwner,
        uint256 deadline
    );
    event NewOwnerRevoked(address owner, address revokedOwner);
    event Paused();
    event PriceFeedSet(address priceFeed);
    event Unpaused();

    function setFeeReceiver(address _feeReceiver) external;

    function setGuardian(address _guardian) external;

    /**
     * @notice Sets the global pause state of the protocol. Pausing is used to mitigate risks in exceptional circumstances.
     * Functionalities affected by pausing are:
     * - New borrowing is not possible
     * - New collateral deposits are not possible
     * - New stability pool deposits are not possible
     * @param what If true the protocol is paused
     */
    function setPaused(bool _paused) external;

    function setPriceFeed(address _priceFeed) external;

    function feeReceiver() external view returns (address);

    function guardian() external view returns (address);

    function priceFeed() external view returns (address);

    function startTime() external view returns (uint256);
}
