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

pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@layerzerolabs/solidity-examples/contracts/lzApp/NonblockingLzApp.sol";

/// @title Omnichain Governance Executor
/// @notice Executes the proposal transactions sent from the main chain
/// @dev The owner of this contract controls LayerZero configuration. When used in production the owner should be set to a Timelock or this contract itself
/// This implementation is non-blocking meaning the failed messages will not block the future messages from the source. For the blocking behavior derive the contract from LzApp
contract OmnichainGovernanceExecutorL2 is NonblockingLzApp, ReentrancyGuard {
    using BytesLib for bytes;
    using ExcessivelySafeCall for address;

    event ProposalExecuted(bytes payload);
    event ProposalFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _reason);

    constructor(address _endpoint, address _owner) NonblockingLzApp(_endpoint) Ownable(_owner) {}

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        bytes32 hashedPayload = keccak256(_payload);
        uint256 gasToStoreAndEmit = 30000; // enough gas to ensure we can store the payload and emit the event

        (bool success, bytes memory reason) = address(this).excessivelySafeCall(gasleft() - gasToStoreAndEmit, 150, abi.encodeWithSelector(this.nonblockingLzReceive.selector, _srcChainId, _srcAddress, _nonce, _payload));
        // try-catch all errors/exceptions
        if (!success) {
            failedMessages[_srcChainId][_srcAddress][_nonce] = hashedPayload;
            emit ProposalFailed(_srcChainId, _srcAddress, _nonce, reason); // Retrieve payload from the src side tx if needed to clear
        }
    }

    /// @notice Executes the proposal
    /// @dev Called by LayerZero Endpoint when a message from the source is received
    function _nonblockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal virtual override {
        (address[] memory targets, uint[] memory values, string[] memory signatures, bytes[] memory calldatas) = abi.decode(_payload, (address[], uint[], string[], bytes[]));

        for (uint i = 0; i < targets.length; i++) {
            _executeTransaction(targets[i], values[i], signatures[i], calldatas[i]);
        }
        emit ProposalExecuted(_payload);
    }

    function _executeTransaction(address target, uint value, string memory signature, bytes memory data) private nonReentrant {
        bytes memory callData = bytes(signature).length == 0 ? data : abi.encodePacked(bytes4(keccak256(bytes(signature))), data);

        // solium-disable-next-line security/no-call-value
        (bool success, ) = target.call{value: value}(callData);
        require(success, "OmnichainGovernanceExecutor: transaction execution reverted");
    }

    receive() external payable {}
}
