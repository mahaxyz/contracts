// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IPrismaCore.sol";

/**
    @title Prisma DAO Interim Admin
    @notice Temporary ownership contract for all Prisma contracts during bootstrap phase. Allows executing
            arbitrary function calls by the deployer following a minimum time before execution.
            The protocol guardian can cancel any proposals and cannot be replaced.
            To avoid a malicious flood attack the number of daily proposals is capped.
 */
contract InterimAdmin is Ownable {
    using Address for address;

    event ProposalCreated(uint256 proposalId, Action[] payload);
    event ProposalExecuted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);

    struct Proposal {
        uint32 createdAt; // timestamp when the proposal was created
        uint32 canExecuteAfter; // earliest timestamp when proposal can be executed (0 if not passed)
        bool processed; // set to true once the proposal is processed
    }

    struct Action {
        address target;
        bytes data;
    }

    uint256 public constant MIN_TIME_TO_EXECUTION = 1 days;
    uint256 public constant MAX_TIME_TO_EXECUTION = 3 weeks;
    uint256 public constant MAX_DAILY_PROPOSALS = 3;

    IPrismaCore public immutable prismaCore;
    address public adminVoting;

    Proposal[] proposalData;
    mapping(uint256 => Action[]) proposalPayloads;
    mapping(uint256 => uint256) dailyProposalsCount;

    constructor(address _prismaCore) {
        prismaCore = IPrismaCore(_prismaCore);
    }

    function setAdminVoting(address _adminVoting) external onlyOwner {
        require(adminVoting == address(0), "Already set");
        require(_adminVoting.isContract(), "adminVoting must be a contract");
        adminVoting = _adminVoting;
    }

    /**
        @notice The total number of votes created
     */
    function getProposalCount() external view returns (uint256) {
        return proposalData.length;
    }

    /**
        @notice Gets information on a specific proposal
     */
    function getProposalData(
        uint256 id
    )
        external
        view
        returns (uint256 createdAt, uint256 canExecuteAfter, bool executed, bool canExecute, Action[] memory payload)
    {
        Proposal memory proposal = proposalData[id];
        payload = proposalPayloads[id];
        canExecute = (!proposal.processed &&
            proposal.canExecuteAfter < block.timestamp &&
            proposal.canExecuteAfter + MAX_TIME_TO_EXECUTION > block.timestamp);

        return (proposal.createdAt, proposal.canExecuteAfter, proposal.processed, canExecute, payload);
    }

    /**
        @notice Create a new proposal
        @param payload Tuple of [(target address, calldata), ... ] to be
                       executed if the proposal is passed.
     */
    function createNewProposal(Action[] calldata payload) external onlyOwner {
        require(payload.length > 0, "Empty payload");
        uint256 day = block.timestamp / 1 days;
        uint256 currentDailyCount = dailyProposalsCount[day];
        require(currentDailyCount < MAX_DAILY_PROPOSALS, "MAX_DAILY_PROPOSALS");
        uint loopEnd = payload.length;
        for (uint256 i; i < loopEnd; i++) {
            require(!_isSetGuardianPayload(payload[i]), "Cannot change guardian");
        }
        dailyProposalsCount[day] = currentDailyCount + 1;
        uint256 idx = proposalData.length;
        proposalData.push(
            Proposal({
                createdAt: uint32(block.timestamp),
                canExecuteAfter: uint32(block.timestamp + MIN_TIME_TO_EXECUTION),
                processed: false
            })
        );

        for (uint256 i = 0; i < payload.length; i++) {
            proposalPayloads[idx].push(payload[i]);
        }
        emit ProposalCreated(idx, payload);
    }

    /**
        @notice Cancels a pending proposal
        @dev Can only be called by the guardian to avoid malicious proposals
             The guardian cannot cancel a proposal where the only action is
             changing the guardian.
        @param id Proposal ID
     */
    function cancelProposal(uint256 id) external {
        require(msg.sender == owner() || msg.sender == prismaCore.guardian(), "Unauthorized");
        require(id < proposalData.length, "Invalid ID");
        proposalData[id].processed = true;
        emit ProposalCancelled(id);
    }

    /**
        @notice Execute a proposal's payload
        @dev Can only be called if the proposal has been active for at least `MIN_TIME_TO_EXECUTION`
        @param id Proposal ID
     */
    function executeProposal(uint256 id) external onlyOwner {
        require(id < proposalData.length, "Invalid ID");

        Proposal memory proposal = proposalData[id];
        require(!proposal.processed, "Already processed");

        uint256 executeAfter = proposal.canExecuteAfter;
        require(executeAfter < block.timestamp, "MIN_TIME_TO_EXECUTION");
        require(executeAfter + MAX_TIME_TO_EXECUTION > block.timestamp, "MAX_TIME_TO_EXECUTION");

        proposalData[id].processed = true;

        Action[] storage payload = proposalPayloads[id];
        uint256 payloadLength = payload.length;

        for (uint256 i = 0; i < payloadLength; i++) {
            payload[i].target.functionCall(payload[i].data);
        }
        emit ProposalExecuted(id);
    }

    /**
        @dev Allow accepting ownership transfer of `PrismaCore`
     */
    function acceptTransferOwnership() external onlyOwner {
        prismaCore.acceptTransferOwnership();
    }

    /**
        @dev Restricted method to transfer ownership of `PrismaCore`
             to the actual Admin voting contract
     */
    function transferOwnershipToAdminVoting() external {
        require(msg.sender == owner() || msg.sender == prismaCore.guardian(), "Unauthorized");
        prismaCore.commitTransferOwnership(adminVoting);
    }

    function _isSetGuardianPayload(Action memory action) internal pure returns (bool) {
        bytes memory data = action.data;
        // Extract the call sig from payload data
        bytes4 sig;
        assembly {
            sig := mload(add(data, 0x20))
        }
        return sig == IPrismaCore.setGuardian.selector;
    }
}
