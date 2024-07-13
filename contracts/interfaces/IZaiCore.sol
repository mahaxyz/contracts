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

interface IZaiCore {
    // event FeeReceiverSet(address feeReceiver);
    // event GuardianSet(address guardian);
    // event NewOwnerAccepted(address oldOwner, address owner);
    // event NewOwnerCommitted(
    //     address owner,
    //     address pendingOwner,
    //     uint256 deadline
    // );
    // event NewOwnerRevoked(address owner, address revokedOwner);
    // event Paused();
    // event PriceFeedSet(address priceFeed);
    // event Unpaused();

    /**
     * @notice Set the receiver of all fees across the protocol
     * @param _feeReceiver Address of the fee's recipient
     */
    function setFeeReceiver(address _feeReceiver) external;

    /**
     * @notice Set the guardian address. The guardian can execute some emergency actions
     * @param _guardian Guardian address
     */
    function setGuardian(address _guardian) external;

    /**
     * @notice Sets the global pause state of the protocol. Pausing is used to mitigate risks in exceptional circumstances.
     * Functionalities affected by pausing are:
     * - New borrowing is not possible
     * - New collateral deposits are not possible
     * - New stability pool deposits are not possible
     * @param what If true the protocol is paused
     */
    function setPaused(bool what) external;

    /**
     * @notice Set the price feed used in the protocol
     * @param _priceFeed Price feed address
     */
    function setPriceFeed(address _priceFeed) external;

    function feeReceiver() external view returns (address);

    function guardian() external view returns (address);

    function owner() external view returns (address);

    function priceFeed() external view returns (address);

    /**
     * @notice System-wide start time, rounded down the nearest epoch week.
     * Other contracts that require access to this should inherit `SystemStart`.
     */
    function startTime() external view returns (uint256);

    function paused() external view returns (bool);
}
