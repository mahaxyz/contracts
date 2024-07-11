// SPDX-License-Identifier: BUSL-1.1

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

// import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IVestedZeroNFT {
    enum VestCategory {
        PRIVATE_SALE,
        EARLY_ZERO,
        NORMAL,
        AIRDROP
    }

    struct LockDetails {
        uint256 cliffDuration;
        uint256 unlockDate;
        uint256 pendingClaimed;
        uint256 pending;
        uint256 upfrontClaimed;
        uint256 upfront;
        uint256 linearDuration;
        uint256 createdAt;
        bool hasPenalty;
        VestCategory category;
    }

    /// Mints a vesting nft for a user. This is a privileged function meant to only be called by a contract or a deployer
    /// @param who For whom we are vesting tokesn for
    /// @param pending How much tokens the user gets after the cliff is over during the linear vesting
    /// @param upfront How much tokens the user gets upfront (befoer the cliff after the unlockDate)
    /// @param linearDuration How long is the linear vesting
    /// @param cliffDuration How long is the cliff (normally 1 month)
    /// @param unlockDate When will this vest start
    /// @param hasPenalty Will the user get penalized for withdrawing early (Radiant-style punishements)
    /// @param category A read-only value just to keep track of a NFT.
    function mint(
        address who,
        uint256 pending,
        uint256 upfront,
        uint256 linearDuration,
        uint256 cliffDuration,
        uint256 unlockDate,
        bool hasPenalty,
        VestCategory category
    ) external returns (uint256);

    function togglePause() external;

    function freeze(uint256 tokenId, bool what) external;

    /// Used by an admin to bulk update the cliff duration and linear distribution for a vest
    /// @param tokenIds the nfts to update
    /// @param linearDurations the linear duration to update with
    /// @param cliffDurations the cliff duration to update with
    function updateCliffDuration(
        uint256[] memory tokenIds,
        uint256[] memory linearDurations,
        uint256[] memory cliffDurations
    ) external;

    /// How much ZERO tokens this vesting nft can claim
    /// @param tokenId the id of the nft contract
    /// @return upfront how much tokens upfront this nft can claim
    /// @return pending how much tokens in the linear vesting (after the cliff) this nft can claim
    function claimable(
        uint256 tokenId
    ) external view returns (uint256 upfront, uint256 pending);

    /// Executes a claim of tokens for a given nft
    /// @param id the nft id to claim tokens for
    function claim(uint256 id) external returns (uint256 toClaim);

    /// How much tokens have been claimed so far
    /// @param tokenId the nft id
    function claimed(uint256 tokenId) external view returns (uint256);

    /// How much tokens haven't been claimed so far
    /// @param tokenId the nft id
    function unclaimed(uint256 tokenId) external view returns (uint256);

    /// Calculate how much penalty the user will have to pay
    /// @param tokenId the nft id
    function penalty(uint256 tokenId) external view returns (uint256);

    /// Splits a vesting NFT into smaller vests so that it can be easily traded
    /// @param tokenId The nft to split for
    /// @param fraction By how much bps the split should happen (10000 bps = 100%)
    function split(uint256 tokenId, uint256 fraction) external;

    /// In case the a nft gets sold in the OTC market, would be great if the team could
    /// claim fees against the vested tokens
    /// @param salePrice The price the asset is going to be sold for
    /// @return royaltyReceiver The address that will receive the royalties
    /// @return royaltyAmount The royalty amount
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view returns (address, uint256);

    /// Claim unvested tokens by the bonus staking contract
    /// @param tokenId The nft id
    function claimUnvested(uint256 tokenId) external;

    /// Metadata helper for nft platforms like openzea
    /// @param tokenId The nft id
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
