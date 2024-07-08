// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../dependencies/PrismaOwnable.sol";

interface IConvexDepositToken {
    function initialize(uint256 pid) external;

    function lpToken() external view returns (address);

    function depositPid() external view returns (uint256);
}

/**
    @notice Prisma Convex Factory
    @title Deploys clones of `ConvexDepositToken` as directed by the Prisma DAO
 */
contract ConvexFactory is PrismaOwnable {
    using Clones for address;

    address public depositTokenImpl;

    mapping(uint256 pid => address depositToken) public getDepositToken;

    event NewDeployment(address depositToken, address lpToken, uint256 convexPid);
    event ImplementationSet(address depositTokenImpl);

    constructor(
        address _prismaCore,
        address _depositTokenImpl,
        address[] memory _existingDeployments
    ) PrismaOwnable(_prismaCore) {
        depositTokenImpl = _depositTokenImpl;
        emit ImplementationSet(_depositTokenImpl);

        for (uint i = 0; i < _existingDeployments.length; i++) {
            address depositToken = _existingDeployments[i];
            address lpToken = IConvexDepositToken(depositToken).lpToken();
            uint256 pid = IConvexDepositToken(depositToken).depositPid();
            getDepositToken[pid] = depositToken;
            emit NewDeployment(depositToken, lpToken, pid);
        }
    }

    /**
        @dev After calling this function, the owner should also call `Vault.registerReceiver`
             to enable PRISMA emissions on the newly deployed `ConvexDepositToken`
     */
    function deployNewInstance(uint256 pid) external onlyOwner {
        // cloning reverts if duplicating the same pid with the same implementation
        // it is intentionally allowed to redeploy using the same pid with a new implementation
        address depositToken = depositTokenImpl.cloneDeterministic(bytes32(pid));

        IConvexDepositToken(depositToken).initialize(pid);
        getDepositToken[pid] = depositToken;

        emit NewDeployment(depositToken, IConvexDepositToken(depositToken).lpToken(), pid);
    }

    function getDeterministicAddress(uint256 pid) external view returns (address) {
        return Clones.predictDeterministicAddress(depositTokenImpl, bytes32(pid));
    }

    function setImplementation(address impl) external onlyOwner {
        depositTokenImpl = impl;
        emit ImplementationSet(impl);
    }
}
