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

import {ERC20VotesUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ILocker} from "../../../interfaces/ILocker.sol";
import {ILPOracle} from "../../../interfaces/ILPOracle.sol";
import {IOmnichainStaking} from "../../../interfaces/IOmnichainStaking.sol";
import {IPoolVoter} from "../../../interfaces/IPoolVoter.sol";
import {IAggregatorV3Interface} from "../../../interfaces/IAggregatorV3Interface.sol";
import {IWETH} from "../../../interfaces/IWETH.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/**
 * @title OmnichainStaking
 * @dev An omnichain staking contract that allows users to stake their veNFT
 * and get some voting power. Once staked, the voting power is available cross-chain.
 */
abstract contract OmnichainStakingBase is
    IOmnichainStaking,
    ERC20VotesUpgradeable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    ILocker public locker;
    ILocker public __; // unwanted variable to keep storage layout
    IPoolVoter public poolVoter;

    // staking reward variables
    IERC20 public rewardsToken;
    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public rewardsDuration;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    // used to keep track of voting powers for each nft id
    mapping(uint256 => uint256) public lpPower;
    mapping(uint256 => uint256) public tokenPower;

    // used to keep track of ownership of token lockers
    mapping(uint256 => address) public lockedByToken;
    mapping(address => uint256[]) public lockedTokenIdNfts;

    // used to keep track of rewards
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    /// @notice Account that distributes staking rewards
    address public distributor;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the contract with the provided token lockers.
     * @param _locker The address of the token locker contract.
     */
    function __OmnichainStakingBase_init(
        string memory name,
        string memory symbol,
        address _locker,
        address _zeroToken,
        address _poolVoter,
        uint256 _rewardsDuration,
        address _distributor
    ) internal {
        __ERC20Votes_init();
        __Ownable_init(msg.sender);
        __ReentrancyGuard_init();
        __ERC20_init(name, symbol);

        locker = ILocker(_locker);
        poolVoter = IPoolVoter(_poolVoter);
        rewardsToken = IERC20(_zeroToken);
        rewardsDuration = _rewardsDuration;

        // give approvals for increase lock functions
        locker.underlying().approve(_locker, type(uint256).max);

        distributor = _distributor;
    }

    /**
     * @dev Receives an ERC721 token from the lockers and grants voting power accordingly.
     * @param from The address sending the ERC721 token.
     * @param tokenId The ID of the ERC721 token.
     * @param data Additional data.
     * @return ERC721 onERC721Received selector.
     */
    function _onERC721ReceivedInternal(
        address,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) internal returns (bytes4) {
        require(msg.sender == address(locker), "only locker");

        if (data.length > 0)
            (, from, ) = abi.decode(data, (bool, address, uint256));

        updateRewardFor(from);

        // track nft id
        lockedByToken[tokenId] = from;
        lockedTokenIdNfts[from].push(tokenId);

        // set delegate if not set already
        if (delegates(from) == address(0)) _delegate(from, from);

        // mint voting power
        tokenPower[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
        _mint(from, tokenPower[tokenId]);

        return this.onERC721Received.selector;
    }

    /**
     * @dev Gets the details of locked NFTs for a given user.
     * @param _user The address of the user.
     * @return lockedTokenIds The array of locked NFT IDs.
     * @return tokenDetails The array of locked NFT details.
     */
    function getLockedNftDetails(
        address _user
    ) external view returns (uint256[] memory, ILocker.LockedBalance[] memory) {
        uint256 tokenIdsLength = lockedTokenIdNfts[_user].length;
        uint256[] memory lockedTokenIds = lockedTokenIdNfts[_user];

        uint256[] memory tokenIds = new uint256[](tokenIdsLength);
        ILocker.LockedBalance[]
            memory tokenDetails = new ILocker.LockedBalance[](tokenIdsLength);

        for (uint256 i; i < tokenIdsLength; ) {
            tokenDetails[i] = locker.locked(lockedTokenIds[i]);
            tokenIds[i] = lockedTokenIds[i];

            unchecked {
                ++i;
            }
        }

        return (tokenIds, tokenDetails);
    }

    function onERC721Received(
        address to,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return _onERC721ReceivedInternal(to, from, tokenId, data);
    }

    /**
     * @dev Unstakes a regular token NFT and transfers it back to the user.
     * @param tokenId The ID of the regular token NFT to unstake.
     */
    function unstakeToken(uint256 tokenId) external updateReward(msg.sender) {
        require(lockedByToken[tokenId] != address(0), "!tokenId");
        address lockedBy_ = lockedByToken[tokenId];
        if (_msgSender() != lockedBy_)
            revert InvalidUnstaker(_msgSender(), lockedBy_);

        delete lockedByToken[tokenId];
        lockedTokenIdNfts[_msgSender()] = deleteAnElement(
            lockedTokenIdNfts[_msgSender()],
            tokenId
        );

        // reset and burn voting power
        _burn(msg.sender, tokenPower[tokenId]);
        tokenPower[tokenId] = 0;
        poolVoter.reset(msg.sender);

        locker.safeTransferFrom(address(this), msg.sender, tokenId);
    }

    /**
     * @dev Updates the lock duration for a specific NFT.
     * @param tokenId The ID of the NFT for which to update the lock duration.
     * @param newLockDuration The new lock duration in seconds.
     */
    function increaseLockDuration(
        uint256 tokenId,
        uint256 newLockDuration
    ) external {
        require(newLockDuration > 0, "!newLockAmount");

        require(msg.sender == lockedByToken[tokenId], "!tokenId");
        locker.increaseUnlockTime(tokenId, newLockDuration);

        // update voting power
        _burn(msg.sender, tokenPower[tokenId]);
        tokenPower[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
        _mint(msg.sender, tokenPower[tokenId]);

        // reset all the votes for the user
        poolVoter.reset(msg.sender);
    }

    /**
     * @dev Updates the lock amount for a specific NFT.
     * @param tokenId The ID of the NFT for which to update the lock amount.
     * @param newLockAmount The new lock amount in tokens.
     */
    function increaseLockAmount(
        uint256 tokenId,
        uint256 newLockAmount
    ) external {
        require(newLockAmount > 0, "!newLockAmount");

        require(msg.sender == lockedByToken[tokenId], "!tokenId");
        locker.underlying().transferFrom(
            msg.sender,
            address(this),
            newLockAmount
        );
        locker.increaseAmount(tokenId, newLockAmount);

        // update voting power
        _burn(msg.sender, tokenPower[tokenId]);
        tokenPower[tokenId] = _getTokenPower(locker.balanceOfNFT(tokenId));
        _mint(msg.sender, tokenPower[tokenId]);

        // reset all the votes for the user
        poolVoter.reset(msg.sender);
    }

    /**
     * @dev Updates the reward for a given account.
     * @param account The address of the account.
     */
    function updateRewardFor(address account) public {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    /**
     * Returns how much max voting power this locker will give out for the
     * given amount of tokens. This varies for the instance of locker.
     *
     * @param amount The amount of tokens to give voting power for.
     */
    function getTokenPower(
        uint256 amount
    ) external view returns (uint256 power) {
        power = _getTokenPower(amount);
    }

    /**
     * @dev Calculates the amount of rewards earned by an account.
     * @param account The address of the account.
     * @return The amount of rewards earned.
     */
    function earned(address account) public view returns (uint256) {
        return
            (balanceOf(account) *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    /**
     * @dev Calculates the last time rewards were applicable.
     * @return The last time rewards were applicable.
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        uint256 time = block.timestamp < periodFinish
            ? block.timestamp
            : periodFinish;
        return time;
    }

    function totalNFTStaked(address who) public view returns (uint256) {
        return lockedTokenIdNfts[who].length;
    }

    /**
     * @dev Calculates the reward per token.
     * @return The reward per token.
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }

        uint256 timeElapsed = lastTimeRewardApplicable() - lastUpdateTime;
        uint256 rewardPerTokenChange = (timeElapsed * rewardRate * 1e18) /
            totalSupply();

        return rewardPerTokenStored + rewardPerTokenChange;
    }

    function notifyRewardAmount(
        uint256 reward
    ) external updateReward(address(0)) {
        require(msg.sender == distributor, "!distributor");
        rewardsToken.transferFrom(msg.sender, address(this), reward);

        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(
            rewardRate <= balance / rewardsDuration,
            "Provided reward too high"
        );

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function recoverERC20(
        address tokenAddress,
        uint256 tokenAmount
    ) external onlyOwner {
        require(
            tokenAddress != address(rewardsToken),
            "Cannot withdraw the staking token"
        );
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * Admin only function to set the pool voter contract
     *
     * @param what The new address for the pool voter contract
     */
    function setPoolVoter(address what) external onlyOwner {
        emit PoolVoterUpdated(address(poolVoter), what);
        poolVoter = IPoolVoter(what);
    }

    /**
     * Admin only function to set the rewards distributor
     *
     * @param what The new address for the rewards distributor
     */
    function setRewardDistributor(address what) external onlyOwner {
        distributor = what;
    }

    /**
     * Temporary fix to init the delegate variable for a given user. This is
     * an admin only function as it's a temporary fix. This can be permissionless.
     *
     * @param who The who for whom delegate should be called.
     */
    function initDelegates(address[] memory who) external {
        for (uint i = 0; i < who.length; i++) {
            require(delegates(who[i]) == address(0), "delegate already set");
            _delegate(who[i], who[i]);
        }
    }

    /**
     * @dev Transfers rewards to the caller.
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev This is an ETH variant of the get rewards function. It unwraps the token and sends out
     * raw ETH to the user.
     */
    function getRewardETH() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IWETH(address(rewardsToken)).withdraw(reward);
            (bool ethSendSuccess, ) = msg.sender.call{value: reward}("");
            require(ethSendSuccess, "eth send failed");
            emit RewardPaid(msg.sender, reward);
        }
    }

    /**
     * @dev Prevents transfers of voting power.
     */
    function transfer(address, uint256) public pure override returns (bool) {
        revert("transfer disabled");
    }

    /**
     * @dev Prevents transfers of voting power.
     */
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("transferFrom disabled");
    }

    /**
     * @dev Deletes an element from an array.
     * @param elements The array to delete from.
     * @param element The element to delete.
     * @return The updated array.
     */
    function deleteAnElement(
        uint256[] memory elements,
        uint256 element
    ) internal pure returns (uint256[] memory) {
        uint256 length = elements.length;
        uint256 count;

        for (uint256 i = 0; i < length; i++) {
            if (elements[i] != element) {
                count++;
            }
        }

        uint256[] memory updatedArray = new uint256[](count);
        uint256 index;

        for (uint256 i = 0; i < length; i++) {
            if (elements[i] != element) {
                updatedArray[index] = elements[i];
                index++;
            }
        }

        return updatedArray;
    }

    /**
     * @dev Modifier to update the reward for a given account.
     * @param account The address of the account.
     */
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function _getTokenPower(
        uint256 amount
    ) internal view virtual returns (uint256 power);
}
