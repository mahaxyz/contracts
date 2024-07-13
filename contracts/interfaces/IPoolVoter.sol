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

interface IPoolVoter {
    event GaugeCreated(
        address indexed gauge,
        address creator,
        address indexed bribe,
        address indexed pool
    );
    event Voted(address indexed voter, uint tokenId, int256 weight);
    event Abstained(uint tokenId, int256 weight);
    event Deposit(
        address indexed lp,
        address indexed gauge,
        uint tokenId,
        uint amount
    );
    event Withdraw(
        address indexed lp,
        address indexed gauge,
        uint tokenId,
        uint amount
    );
    event NotifyReward(
        address indexed sender,
        address indexed reward,
        uint amount
    );
    event DistributeReward(
        address indexed sender,
        address indexed gauge,
        uint amount
    );
    event Attach(address indexed owner, address indexed gauge, uint tokenId);
    event Detach(address indexed owner, address indexed gauge, uint tokenId);
    event Whitelisted(address indexed whitelister, address indexed token);

    event StakingTokenUpdated(
        address indexed oldStaking,
        address indexed newStaking
    );
    event RewardTokenUpdated(
        address indexed oldReward,
        address indexed newReward
    );
    event LzEndpointUpdated(
        address indexed oldLzEndpoint,
        address indexed newLzEndpoint
    );
    event MainnetEmissionsUpdated(
        address indexed oldMainnetEmissions,
        address indexed newMainnetEmissions
    );
    error ResetNotAllowed();

    function reset(address _who) external;

    function poke(address _who) external;

    function vote(
        address[] calldata _poolVote,
        uint256[] calldata _weights
    ) external;

    function length() external view returns (uint);

    function notifyRewardAmount(uint256 amount) external;

    // function updateFor(address[] memory _gauges) external;

    // function updateForRange(uint start, uint end) external;

    // function updateAll() external;

    // function updateGauge(address _gauge) external;

    // function claimRewards(
    //     address[] memory _gauges,
    //     address[][] memory _tokens
    // ) external;

    // function claimBribes(
    //     address[] memory _bribes,
    //     address[][] memory _tokens,
    //     uint _tokenId
    // ) external;

    // function claimFees(
    //     address[] memory _fees,
    //     address[][] memory _tokens,
    //     uint _tokenId
    // ) external;

    function distribute(address _gauge) external;

    function distribute() external;

    function distribute(address[] memory _gauges) external;
}
