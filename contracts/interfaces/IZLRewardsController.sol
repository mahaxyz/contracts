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

import "./IIncentivesController.sol";

interface IZLRewardsController {
    // Info of each user.
    // reward = user.`amount` * pool.`accRewardPerShare` - `rewardDebt`
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastClaimTime;
    }

    // Info of each pool.
    struct PoolInfo {
        uint256 totalSupply;
        uint256 allocPoint; // How many allocation points assigned to this pool.
        uint256 lastRewardTime; // Last second that reward distribution occurs.
        uint256 accRewardPerShare; // Accumulated rewards per share, times ACC_REWARD_PRECISION. See below.
        IIncentivesController onwardIncentives;
    }

    // Info about token emissions for a given time period.
    struct EmissionPoint {
        uint128 startTimeOffset;
        uint128 rewardsPerSecond;
    }

    // Info about ending time of reward emissions
    struct EndingTime {
        uint256 estimatedTime;
        uint256 lastUpdatedTime;
        uint256 updateCadence;
    }

    /********************** Events ***********************/
    // Emitted when rewardPerSecond is updated
    event RewardsPerSecondUpdated(
        uint256 indexed rewardsPerSecond,
        bool persist
    );

    event BalanceUpdated(
        address indexed token,
        address indexed user,
        uint256 balance,
        uint256 totalSupply
    );

    event EmissionScheduleAppended(
        uint256[] startTimeOffsets,
        uint256[] rewardsPerSeconds
    );

    event ChefReserveLow(uint256 indexed _balance);

    event Disqualified(address indexed user);

    event OnwardIncentivesUpdated(
        address indexed _token,
        IIncentivesController _incentives
    );

    event BountyManagerUpdated(address indexed _bountyManager);

    event BatchAllocPointsUpdated(address[] _tokens, uint256[] _allocPoints);

    event AuthorizedContractUpdated(address _contract, bool _authorized);

    event EndingTimeUpdateCadence(uint256 indexed _lapse);

    event RewardDeposit(uint256 indexed _amount);

    /********************** Errors ***********************/
    error AddressZero();

    error UnknownPool();

    error PoolExists();

    error AlreadyStarted();

    error NotAllowed();

    error ArrayLengthMismatch();

    error NotAscending();

    error ExceedsMaxInt();

    error InvalidStart();

    error InvalidRToken();

    error InsufficientPermission();

    error AuthorizationAlreadySet();

    error NotMFD();

    error NotWhitelisted();

    error BountyOnly();

    error NotEligible();

    error CadenceTooLong();

    error EligibleRequired();

    error NotRTokenOrMfd();

    error OutOfRewards();

    error NothingToVest();

    error DuplicateSchedule();

    error ValueZero();
}
