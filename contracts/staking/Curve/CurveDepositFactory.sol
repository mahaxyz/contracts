// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "../../dependencies/PrismaOwnable.sol";
import "../../interfaces/ICurveProxy.sol";

interface ICurveDepositToken {
    function initialize(address _gauge) external;

    function lpToken() external view returns (address);

    function gauge() external view returns (address);
}

/**
    @notice Prisma Curve Factory
    @title Deploys clones of `CurveDepositToken` as directed by the Prisma DAO
 */
contract CurveFactory is PrismaOwnable {
    using Clones for address;

    ICurveProxy public immutable curveProxy;
    address public depositTokenImpl;

    mapping(address gauge => address depositToken) public getDepositToken;

    event NewDeployment(address depositToken, address lpToken, address gauge);
    event ImplementationSet(address depositTokenImpl);

    constructor(
        address _prismaCore,
        ICurveProxy _curveProxy,
        address _depositTokenImpl,
        address[] memory _existingDeployments
    ) PrismaOwnable(_prismaCore) {
        curveProxy = _curveProxy;
        depositTokenImpl = _depositTokenImpl;
        emit ImplementationSet(_depositTokenImpl);

        for (uint i = 0; i < _existingDeployments.length; i++) {
            address depositToken = _existingDeployments[i];
            address lpToken = ICurveDepositToken(depositToken).lpToken();
            address gauge = ICurveDepositToken(depositToken).gauge();
            getDepositToken[gauge] = depositToken;
            emit NewDeployment(depositToken, lpToken, gauge);
        }
    }

    /**
        @dev After calling this function, the owner should also call `Vault.registerReceiver`
             to enable PRISMA emissions on the newly deployed `CurveDepositToken`
     */
    function deployNewInstance(address gauge) external onlyOwner {
        // no duplicate deployments because deposits and rewards must route via `CurveProxy`
        require(getDepositToken[gauge] == address(0), "Deposit token already deployed");
        address depositToken = depositTokenImpl.cloneDeterministic(bytes32(bytes20(gauge)));

        curveProxy.setPerGaugeApproval(depositToken, gauge);
        ICurveDepositToken(depositToken).initialize(gauge);
        getDepositToken[gauge] = depositToken;

        emit NewDeployment(depositToken, ICurveDepositToken(depositToken).lpToken(), gauge);
    }

    function getDeterministicAddress(address gauge) external view returns (address) {
        return Clones.predictDeterministicAddress(depositTokenImpl, bytes32(bytes20(gauge)));
    }

    function setImplementation(address impl) external onlyOwner {
        depositTokenImpl = impl;
        emit ImplementationSet(impl);
    }
}
