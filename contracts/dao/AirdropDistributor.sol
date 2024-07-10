// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../interfaces/ITokenLocker.sol";
import "../interfaces/IVault.sol";

interface IClaimCallback {
    function claimCallback(address claimant, uint256 amount) external returns (bool success);
}

/**
    @title Prisma Airdrop Distributor
    @notice Distributes PRISMA to veCRV holders that voted in favor of Prisma's
            initial Curve governance proposal, and to early users who interacted
            with the protocol prior to token emissions.
    @dev Airdropped PRISMA tokens are given as a locked position. Distribution
         is via a merkle proof. The proof and script used to create are available
         on Github: https://github.com/prisma-fi/airdrop-proofs
 */
contract AirdropDistributor is Ownable {
    using Address for address;

    bytes32 public merkleRoot;
    uint256 public canClaimUntil;

    mapping(uint256 => uint256) private claimedBitMap;
    mapping(address receiver => address callback) public claimCallback;

    IERC20 public immutable token;
    ITokenLocker public immutable locker;
    address public immutable vault;

    uint256 private immutable lockToTokenRatio;
    uint256 private immutable CLAIM_LOCK_WEEKS;
    uint256 public constant CLAIM_DURATION = 13 weeks;

    event Claimed(address indexed claimant, address indexed receiver, uint256 index, uint256 amount);
    event MerkleRootSet(bytes32 root, uint256 canClaimUntil);

    constructor(IERC20 _token, ITokenLocker _locker, address _vault, uint256 lockWeeks) {
        token = _token;
        locker = _locker;
        vault = _vault;
        CLAIM_LOCK_WEEKS = lockWeeks;

        lockToTokenRatio = _locker.lockToTokenRatio();
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        require(merkleRoot == bytes32(0), "merkleRoot already set");
        merkleRoot = _merkleRoot;
        canClaimUntil = block.timestamp + CLAIM_DURATION;
        emit MerkleRootSet(_merkleRoot, canClaimUntil);
    }

    function sweepUnclaimedTokens() external {
        require(merkleRoot != bytes32(0), "merkleRoot not set");
        require(block.timestamp > canClaimUntil, "Claims still active");
        uint256 amount = token.allowance(vault, address(this));
        require(amount > 0, "Nothing to sweep");
        token.transferFrom(vault, address(this), amount);
        token.approve(vault, amount);
        IPrismaVault(vault).increaseUnallocatedSupply(amount);
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /**
        @dev `amount` is after dividing by `locker.lockToTokenRatio()`
     */
    function claim(
        address claimant,
        address receiver,
        uint256 index,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external {
        if (msg.sender != claimant) {
            require(msg.sender == owner(), "onlyOwner");
            require(claimant.isContract(), "Claimant must be a contract");
        }

        require(merkleRoot != bytes32(0), "merkleRoot not set");
        require(block.timestamp < canClaimUntil, "Claims period has finished");
        require(!isClaimed(index), "Already claimed");

        bytes32 node = keccak256(abi.encodePacked(index, claimant, amount));
        require(MerkleProof.verifyCalldata(merkleProof, merkleRoot, node), "Invalid proof");

        _setClaimed(index);
        token.transferFrom(vault, address(this), amount * lockToTokenRatio);
        locker.lock(receiver, amount, CLAIM_LOCK_WEEKS);

        if (claimant != receiver) {
            address callback = claimCallback[receiver];
            if (callback != address(0)) IClaimCallback(callback).claimCallback(claimant, amount);
        }

        emit Claimed(claimant, receiver, index, amount * lockToTokenRatio);
    }

    /**
        @notice Set a claim callback contract
        @dev When set, claims directed to the caller trigger a callback to this address
     */
    function setClaimCallback(address _callback) external returns (bool) {
        claimCallback[msg.sender] = _callback;

        return true;
    }
}
