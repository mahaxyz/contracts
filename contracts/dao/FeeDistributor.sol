// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ITokenLocker.sol";
import "../dependencies/PrismaOwnable.sol";
import "../dependencies/SystemStart.sol";
import "../dependencies/DelegatedOps.sol";

contract FeeDistributor is PrismaOwnable, SystemStart, DelegatedOps {
    using SafeERC20 for IERC20;

    ITokenLocker public immutable tokenLocker;

    // fee token -> week -> total amount received that week
    mapping(address token => uint128[65535]) public weeklyFeeAmounts;
    // user -> fee token -> data about the active stream
    mapping(address account => mapping(address feeToken => uint256 claimFromWeek)) public accountClaimWeek;

    // array of all fee tokens that have been added
    address[] public feeTokens;
    // private mapping for tracking which addresses were added to `feeTokens`
    mapping(address token => FeeTokenData) feeTokenData;

    struct FeeTokenData {
        bool isRegistered;
        uint16 firstWeek;
        uint16 lastWeek;
    }

    struct BoundedClaim {
        address token;
        uint256 claimFromWeek;
        uint256 claimUntilWeek;
    }

    event NewFeeToken(address token);
    event FeesReceived(address indexed caller, address indexed token, uint256 indexed week, uint256 amount);
    event FeesClaimed(
        address indexed account,
        address indexed receiver,
        address indexed token,
        uint256 claimFromWeek,
        uint256 claimUntilWeek,
        uint256 amount
    );

    constructor(address _prismaCore, ITokenLocker _tokenLocker) PrismaOwnable(_prismaCore) SystemStart(_prismaCore) {
        tokenLocker = _tokenLocker;
    }

    function feeTokensLength() external view returns (uint) {
        return feeTokens.length;
    }

    /**
        @notice Get an array of claimable amounts of different tokens accrued from protocol fees
        @param account Address to query claimable amounts for
        @param tokens List of tokens to query claimable amounts of
     */
    function claimable(address account, address[] calldata tokens) external view returns (uint256[] memory amounts) {
        uint256 currentWeek = getWeek();
        amounts = new uint256[](tokens.length);
        if (currentWeek > 0) {
            for (uint256 i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                FeeTokenData memory data = feeTokenData[token];

                uint256 claimFromWeek = accountClaimWeek[account][token];
                if (claimFromWeek < data.firstWeek) claimFromWeek = data.firstWeek;

                uint256 claimUntilWeek = data.lastWeek + 1;
                if (claimUntilWeek > currentWeek) claimUntilWeek = currentWeek;

                amounts[i] = _getClaimable(account, token, claimFromWeek, claimUntilWeek);
            }
        }
        return amounts;
    }

    /**
        @notice Get the current weekly claim bounds for claimable tokens for `account`
        @dev Returned values are used as inputs in `claimWithBounds`. A response of
             `(0, 0)` indicates the account has nothing claimable.
        @param account Address to query claim bounds for
        @param token Token to query claim bounds for
     */
    function getClaimBounds(
        address account,
        address token
    ) external view returns (uint256 claimFromWeek, uint256 claimUntilWeek) {
        uint256 currentWeek = getWeek();
        if (currentWeek == 0) return (0, 0);

        bool canClaim;
        FeeTokenData memory data = feeTokenData[token];

        claimFromWeek = accountClaimWeek[account][token];
        if (claimFromWeek < data.firstWeek) claimFromWeek = data.firstWeek;

        claimUntilWeek = data.lastWeek + 1;
        if (claimUntilWeek > currentWeek) claimUntilWeek = currentWeek;

        for (uint256 i = claimFromWeek; i < claimUntilWeek; i++) {
            uint256 weight = tokenLocker.getAccountWeightAt(account, i);
            if (weight == 0) continue;
            uint256 totalWeight = tokenLocker.getTotalWeightAt(i);
            uint256 amount = (weeklyFeeAmounts[token][i] * weight) / totalWeight;
            if (amount > 0) {
                claimFromWeek = i;
                canClaim = true;
                break;
            }
        }

        claimUntilWeek = claimFromWeek + 1;
        for (uint256 i = currentWeek - 1; i > claimFromWeek; i--) {
            uint256 weight = tokenLocker.getAccountWeightAt(account, i);
            if (weight == 0) continue;
            uint256 totalWeight = tokenLocker.getTotalWeightAt(i);
            uint256 amount = (weeklyFeeAmounts[token][i] * weight) / totalWeight;
            if (amount > 0) {
                claimUntilWeek = i + 1;
                if (claimUntilWeek > currentWeek) claimUntilWeek = currentWeek;
                canClaim = true;
                break;
            }
        }

        if (canClaim) return (claimFromWeek, claimUntilWeek);
        else return (0, 0);
    }

    /**
        @notice Register a new fee token to be distributed
        @dev Only callable by the owner. Once registered, depositing new fees
             is permissionless.
     */
    function registerNewFeeToken(address token) external onlyOwner returns (bool) {
        require(!feeTokenData[token].isRegistered, "Already registered");
        feeTokenData[token] = FeeTokenData({ isRegistered: true, firstWeek: uint16(getWeek()), lastWeek: 0 });
        feeTokens.push(token);

        emit NewFeeToken(token);
        return true;
    }

    /**
        @notice Deposit protocol fees into the contract, to be distributed to lockers
        @dev Caller must have given approval for this contract to transfer `token`
        @param token Token being deposited
        @param amount Amount of the token to deposit
     */
    function depositFeeToken(address token, uint256 amount) external returns (bool) {
        FeeTokenData memory data = feeTokenData[token];
        require(data.isRegistered, "Not a registered fee token");
        if (amount > 0) {
            uint256 received = IERC20(token).balanceOf(address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            received = IERC20(token).balanceOf(address(this)) - received;
            uint256 week = getWeek();
            weeklyFeeAmounts[token][week] = uint128(weeklyFeeAmounts[token][week] + received);
            if (week > data.lastWeek) {
                data.lastWeek = uint16(week);
                feeTokenData[token] = data;
            }
            emit FeesReceived(msg.sender, token, week, amount);
        }
        return true;
    }

    /**
        @notice Claim all accrued protocol fees available to the caller
        @dev Accounts that claim frequently and maintain lock weight should claim
             using this method.
        @param receiver Address to transfer claimed fees to
        @param tokens Array of tokens to claim
        @return claimedAmounts Array of claimed amounts
     */
    function claim(
        address account,
        address receiver,
        address[] calldata tokens
    ) external callerOrDelegated(account) returns (uint256[] memory claimedAmounts) {
        uint256 currentWeek = getWeek();
        require(currentWeek > 0, "No claims in first week");

        uint256 length = tokens.length;
        claimedAmounts = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            address token = tokens[i];
            FeeTokenData memory data = feeTokenData[token];
            require(data.isRegistered, "Not a registered fee token");

            uint256 claimFromWeek = accountClaimWeek[account][token];
            if (claimFromWeek < data.firstWeek) claimFromWeek = data.firstWeek;

            uint256 claimUntilWeek = data.lastWeek + 1;
            if (claimUntilWeek > currentWeek) claimUntilWeek = currentWeek;

            accountClaimWeek[account][token] = currentWeek;
            uint256 amount = _getClaimable(account, token, claimFromWeek, claimUntilWeek);

            if (amount > 0) {
                claimedAmounts[i] = amount;
                IERC20(token).safeTransfer(receiver, amount);
                emit FeesClaimed(account, receiver, token, claimFromWeek, currentWeek, amount);
            }
        }
        return claimedAmounts;
    }

    /**
        @notice Claim accrued protocol fees within a bounded period
        @dev Avoids excess gas usage when an account's first lock is many weeks
             after fee distribution has started, or there is a significant period
             without new fees being added. `claimFromWeek` and `claimUntilWeek`
             can be obtained by calling `getClaimBounds`. Note that if `claimFromWeek`
             is set higher than `accountClaimWeek`, any fees earned in that period
             are forever lost.
        @param receiver Address to transfer claimed fees to
        @param claims Array of (token, claimFromWeek, claimUntilWeek)
        @return claimedAmounts Array of claimed amounts
     */
    function claimWithBounds(
        address account,
        address receiver,
        BoundedClaim[] calldata claims
    ) external callerOrDelegated(account) returns (uint256[] memory claimedAmounts) {
        uint256 currentWeek = getWeek();
        claimedAmounts = new uint256[](claims.length);
        uint256 length = claims.length;
        for (uint i = 0; i < length; i++) {
            address token = claims[i].token;
            uint256 claimFromWeek = claims[i].claimFromWeek;
            uint256 claimUntilWeek = claims[i].claimUntilWeek;
            FeeTokenData memory data = feeTokenData[token];
            require(data.isRegistered, "Not a registered fee token");

            require(claimFromWeek < claimUntilWeek, "claimFromWeek > claimUntilWeek");
            require(claimUntilWeek <= currentWeek, "claimUntilWeek too high");
            require(accountClaimWeek[account][token] <= claimFromWeek, "claimFromWeek too low");

            if (claimFromWeek < data.firstWeek) claimFromWeek = data.firstWeek;
            accountClaimWeek[account][token] = claimUntilWeek;
            uint256 amount = _getClaimable(account, token, claimFromWeek, claimUntilWeek);

            if (amount > 0) {
                claimedAmounts[i] = amount;
                IERC20(token).safeTransfer(receiver, amount);
                emit FeesClaimed(account, receiver, token, claimFromWeek, claimUntilWeek, amount);
            }
        }
        return claimedAmounts;
    }

    function _getClaimable(
        address account,
        address token,
        uint256 claimFromWeek,
        uint256 claimUntilWeek
    ) internal view returns (uint256 claimableAmount) {
        uint128[65535] storage feeAmounts = weeklyFeeAmounts[token];
        for (uint256 i = claimFromWeek; i < claimUntilWeek; i++) {
            uint256 feeAmount = feeAmounts[i];
            if (feeAmount == 0) continue;
            uint256 weight = tokenLocker.getAccountWeightAt(account, i);
            if (weight == 0) continue;
            uint256 totalWeight = tokenLocker.getTotalWeightAt(i);
            claimableAmount += (feeAmount * weight) / totalWeight;
        }
        return claimableAmount;
    }
}
