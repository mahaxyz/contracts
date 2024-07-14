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

import {IDDPool} from "./IDDPool.sol";
import {IDDPlan} from "./IDDPlan.sol";

interface IDDHub {
    error NotAuthorized();
    error NoOp(IDDPool pool);

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event File(bytes32 indexed what, address data);
    event File(IDDPool indexed pool, bytes32 indexed what, address data);
    event File(IDDPool indexed pool, bytes32 indexed what, uint256 data);
    event Wind(IDDPool indexed pool, uint256 amt);
    event Unwind(IDDPool indexed pool, uint256 amt);
    event Fees(IDDPool indexed pool, uint256 amt);
    event Exit(IDDPool indexed pool, address indexed usr, uint256 amt);
    event Cage(IDDPool indexed pool);
    event Cull(IDDPool indexed pool, uint256 ink, uint256 art);
    event Uncull(IDDPool indexed pool, uint256 wad);

    /**
     * @notice Tracking struct for each of the D3M ilks.
     * @param pool   Contract to access external pool and hold balances
     * @param plan   Contract used to calculate target debt
     * @param tau    Time until you can write off the debt [sec]
     * @param writtenOffDebt Debt write off triggered (1 or 0)
     * @param tic    Timestamp when the pool is caged
     */
    struct PoolInfo {
        IDDPool pool; // Access external pool and holds balances
        IDDPlan plan; // How we calculate target debt
        bool isLive;
        uint256 debt;
        uint256 debtCeiling;
    }

    function exec(IDDPool pool) external;

    function evaluatePoolAction(
        IDDPool pool
    ) external view returns (uint256 toSupply, uint256 toWithdraw);

    // --- Administration ---
    /**
        @notice Makes an address authorized to perform auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be authorized
    */
    function rely(address usr) external;

    /**
        @notice De-authorizes an address from performing auth'ed functions.
        @dev msg.sender must be authorized.
        @param usr address to be de-authorized
    */
    function deny(address usr) external;

    /**
        @notice update vow or end addresses.
        @dev msg.sender must be authorized.
        @param what name of what we are updating bytes32("vow"|"end")
        @param data address we are setting it to
    */
    function file(bytes32 what, address data) external;

    /**
        @notice update tau value for D3M ilk.
        @dev msg.sender must be authorized.
        @param ilk  bytes32 of the D3M ilk to be updated
        @param what bytes32("tau") or it will revert
        @param data number of seconds to wait after caging a pool to write off debt
    */
    function file(bytes32 ilk, bytes32 what, uint256 data) external;

    /**
        @notice update plan or pool addresses for D3M ilk.
        @dev msg.sender must be authorized.
        @param ilk  bytes32 of the D3M ilk to be updated
        @param what bytes32("pool"|"plan") or it will revert
        @param data address we are setting it to
    */
    function file(bytes32 ilk, bytes32 what, address data) external;

    /**
        @notice Main function for updating a D3M position.
        Determines the current state and either winds or unwinds as necessary.
        @dev Winding the target position will be constrained by the Ilk debt
        ceiling, the overall DSS debt ceiling and the maximum deposit by the
        pool. Unwinding the target position will be constrained by the number
        of assets available to be withdrawn from the pool.
        @param ilk bytes32 of the D3M ilk name
    */
    function exec(bytes32 ilk) external;

    /**
        @notice Allow Users to return vat gem for Pool Shares.
        This will only occur during Global Settlement when users receive
        collateral for their Dai.
        @param ilk bytes32 of the D3M ilk name
        @param usr address that should receive the shares from the pool
        @param wad amount of gems that the msg.sender is returning
    */
    function exit(bytes32 ilk, address usr, uint256 wad) external;

    /**
        @notice Shutdown a pool.
        This starts the countdown to when the debt can be written off (cull).
        Once called, subsequent calls to `exec` will unwind as much of the
        position as possible.
        @dev msg.sender must be authorized.
        @param ilk bytes32 of the D3M ilk name
    */
    function cage(bytes32 ilk) external;

    /**
        @notice Write off the debt for a caged pool.
        This must occur while vat is live. Can be triggered by auth or
        after tau number of seconds has passed since the pool was caged.
        @dev This will send the pool's debt to the vow as sin and convert its
        collateral to gems.
        @param ilk bytes32 of the D3M ilk name
    */
    function cull(bytes32 ilk) external;

    /**
     * @notice Rollback Write-off (cull) if General Shutdown happened.
     * This function is required to have the collateral back in the vault so it
     * can be taken by End module and eventually be shared to DAI holders (as
     * any other collateral) or maybe even unwinded.
     * @dev This pulls gems from the pool and reopens the urn with the gem amount of ink/art.
     * @param ilk bytes32 of the D3M ilk name
     */
    function uncull(bytes32 ilk) external;

    /**
     * @notice Return pool of an ilk
     * @param ilk   bytes32 of the D3M ilk
     * @return pool address of pool contract
     */
    function pool(bytes32 ilk) external view returns (address);

    /**
     * @notice Return plan of an ilk
     * @param ilk   bytes32 of the D3M ilk
     * @return plan address of plan contract
     */
    function plan(bytes32 ilk) external view returns (address);

    /**
     * @notice Return tau of an ilk
     * @param ilk  bytes32 of the D3M ilk
     * @return tau sec until debt can be written off
     */
    function tau(bytes32 ilk) external view returns (uint256);

    /**
     * @notice Return culled status of an ilk
     * @param ilk  bytes32 of the D3M ilk
     * @return culled whether or not the d3m has been culled
     */
    function culled(bytes32 ilk) external view returns (uint256);

    /**
     * @notice Return tic of an ilk
     * @param ilk  bytes32 of the D3M ilk
     * @return tic timestamp of when d3m is caged
     */
    function tic(bytes32 ilk) external view returns (uint256);
}
