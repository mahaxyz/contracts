// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/PrismaOwnable.sol";
import "../dependencies/SystemStart.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/ITroveManager.sol";
import "../interfaces/IFactory.sol";

interface IFeeDistributor {
    function depositFeeToken(address token, uint256 amount) external returns (bool);
}

interface ICryptoSwap {
    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function price_oracle() external view returns (uint256);

    function price_scale() external view returns (uint256);

    function token() external view returns (address);
}

contract AddLiquidityChecker is PrismaOwnable {
    ICryptoSwap public immutable curvePool;

    uint256 public constant MAX_PCT = 10000;

    // maximum deviation percent between `price_oracle` and `price_scale` when
    // adding liquidity on `curvePool`. protects against sandwich attacks.
    uint256 public maxDeviation;

    constructor(address _core, ICryptoSwap _curve, uint256 _maxDeviation) PrismaOwnable(_core) {
        curvePool = _curve;
        maxDeviation = _maxDeviation;
    }

    function setMaxDeviation(uint256 _maxDeviation) public onlyOwner {
        require(_maxDeviation <= MAX_PCT, "Invalid maxDeviation");

        maxDeviation = uint16(_maxDeviation);
    }

    function canAddLiquidity(address caller, uint256 amountToAdd) external view returns (bool) {
        uint256 priceOracle = curvePool.price_oracle();
        uint256 priceScale = curvePool.price_scale();

        if (priceOracle > priceScale) {
            uint256 delta = priceOracle - priceScale;
            return (delta * MAX_PCT) / priceOracle < maxDeviation;
        } else {
            uint256 delta = priceScale - priceOracle;
            return (delta * MAX_PCT) / priceScale < maxDeviation;
        }
    }
}

contract FeeConverter is PrismaOwnable, SystemStart {
    using SafeERC20 for IERC20;

    IFeeDistributor public immutable feeDistributor;
    IERC20 public immutable debtToken;
    IERC20 public immutable prismaToken;
    IFactory public immutable factory;

    ICryptoSwap public immutable curvePool;
    IERC20 public immutable curvePoolLp;

    uint256 public constant MAX_PCT = 10000;

    ITroveManager[] public troveManagers;

    AddLiquidityChecker public addLiquidityChecker;

    uint16 public updatedWeek;

    // target percent of liquidity within `curvePool` that the protocol should
    // own. if the actual owned percent is less than this, a portion of the
    // week's fees are used to add liquidity.
    uint16 public targetPOLPct;
    // percentage of weekly debt amount used to add liquidity, if protocol owned
    // liquidity is below the target percent.
    uint16 public weeklyDebtPOLPct;

    // maximum percentage of `debtToken` distrubted in a week, relative to the
    // amount within the fee receiver.
    uint16 public maxWeeklyDebtPct;
    // maximum amount of `debtToken` distributed in a week, as an absolute value.
    uint88 public maxWeeklyDebtAmount;

    // debt amount allocated to POL that was not added due to unfavorable conditions
    uint88 public pendingPOLDebtAmount;

    // amount of `debtToken` send to caller each week for processing fees
    // if no POL is added, only half of this amount is given
    uint80 public callerIncentive;

    // collateral -> is for sale via `swapCollateralForDebt`?
    mapping(address collateral => bool isForSale) public isSellingCollateral;

    event WeeklyDebtParamsSet(uint256 maxWeeklyDebtAmount, uint256 maxWeeklyDebtPct);
    event POLParamsSet(uint256 targetPOLPct, uint256 weeklyDebtPOLPct);
    event CallerIncentiveSet(uint256 callerIncentive);
    event AddLiquidityCheckerSet(address addLiquidityChecker);
    event IsSellingCollateralSet(address[] collaterals, bool isSelling);

    event CollateralSold(
        address indexed buyer,
        address indexed collateral,
        uint256 price,
        uint256 amountSold,
        uint256 amountReceived
    );

    event LiquidityAdded(uint256 priceScale, uint256 debtAmount, uint256 prismaAmount, uint256 lpAmountReceived);

    event TroveManagersSynced();
    event InterestCollected();
    event FeeTokenDeposited(uint256 amount);
    event CallerIncentivePaid(address indexed caller, uint256 amount);
    event PendingPOLDebtUpdated(uint256 amount);

    struct InitialParams {
        uint88 maxWeeklyDebtAmount;
        uint16 maxWeeklyDebtPct;
        uint16 targetPOLPct;
        uint16 weeklyDebtPOLPct;
        uint80 callerIncentive;
        AddLiquidityChecker addLiquidityChecker;
        address[] sellCollaterals;
    }

    constructor(
        address _prismaCore,
        address _feeDistributor,
        IERC20 _debtToken,
        IERC20 _prismaToken,
        IFactory _factory,
        ICryptoSwap _curvePool,
        InitialParams memory initialParams
    ) PrismaOwnable(_prismaCore) SystemStart(_prismaCore) {
        feeDistributor = IFeeDistributor(_feeDistributor);
        debtToken = _debtToken;
        prismaToken = _prismaToken;
        factory = _factory;
        curvePool = _curvePool;
        curvePoolLp = IERC20(_curvePool.token());

        _debtToken.approve(_feeDistributor, type(uint256).max);
        _debtToken.approve(address(_curvePool), type(uint256).max);
        _prismaToken.approve(address(_curvePool), type(uint256).max);

        setWeeklyDebtParams(initialParams.maxWeeklyDebtAmount, initialParams.maxWeeklyDebtPct);
        setPOLParams(initialParams.targetPOLPct, initialParams.weeklyDebtPOLPct);
        setAddLiquidityChecker(initialParams.addLiquidityChecker);
        setCallerIncentive(initialParams.callerIncentive);
        setIsSellingCollateral(initialParams.sellCollaterals, true);

        syncTroveManagers();
    }

    function setWeeklyDebtParams(uint256 _maxWeeklyDebtAmount, uint256 _maxWeeklyDebtPct) public onlyOwner {
        require(_maxWeeklyDebtPct <= MAX_PCT, "Invalid maxWeeklyDebtPct");
        maxWeeklyDebtAmount = uint88(_maxWeeklyDebtAmount);
        maxWeeklyDebtPct = uint16(_maxWeeklyDebtPct);

        emit WeeklyDebtParamsSet(_maxWeeklyDebtAmount, _maxWeeklyDebtPct);
    }

    function setPOLParams(uint256 _targetPOLPct, uint256 _weeklyDebtPOLPct) public onlyOwner {
        require(_targetPOLPct <= MAX_PCT, "Invalid targetPOLPct");
        require(_weeklyDebtPOLPct <= MAX_PCT, "Invalid weeklyDebtPOLPct");
        targetPOLPct = uint16(_targetPOLPct);
        weeklyDebtPOLPct = uint16(_weeklyDebtPOLPct);

        emit POLParamsSet(_targetPOLPct, _weeklyDebtPOLPct);
    }

    function setAddLiquidityChecker(AddLiquidityChecker _checker) public onlyOwner {
        addLiquidityChecker = _checker;

        emit AddLiquidityCheckerSet(address(_checker));
    }

    function setCallerIncentive(uint256 _callerIncentive) public onlyOwner {
        callerIncentive = uint80(_callerIncentive);

        emit CallerIncentiveSet(_callerIncentive);
    }

    function setIsSellingCollateral(address[] memory collaterals, bool isSelling) public onlyOwner {
        uint256 length = collaterals.length;
        if (isSelling) {
            IPriceFeed feed = IPriceFeed(PRISMA_CORE.priceFeed());
            for (uint i = 0; i < length; i++) {
                address collateral = collaterals[i];
                // fetch price as validation that collateral can be sold
                feed.fetchPrice(collateral);
                isSellingCollateral[collateral] = true;
            }
        } else {
            for (uint i = 0; i < length; i++) {
                isSellingCollateral[collaterals[i]] = false;
            }
        }

        emit IsSellingCollateralSet(collaterals, isSelling);
    }

    /**
        @notice Swap collateral token for debt
        @dev Collateral is sold at the oracle price without discount, assuming a
             debt token value of $1. Swaps become profitable for the caller when
             the debt token price is under peg. As fees from redemptions are
             also generated only when the debt price is under peg, it is expected
             that redeemers will also call this function in the same action.
     */
    function swapDebtForColl(address collateral, uint256 debtAmount) external returns (uint256) {
        require(isSellingCollateral[collateral], "Collateral sale disabled");
        address receiver = PRISMA_CORE.feeReceiver();

        (uint256 collAmount, uint256 price) = getSwapAmountReceived(collateral, debtAmount);
        debtToken.transferFrom(msg.sender, receiver, debtAmount);
        IERC20(collateral).safeTransferFrom(receiver, msg.sender, collAmount);

        emit CollateralSold(msg.sender, collateral, price, debtAmount, collAmount);
        return collAmount;
    }

    /**
        @notice Get the amount received when swapping collateral for debt
        @dev Intended to be called as a view method
     */
    function getSwapAmountReceived(
        address collateral,
        uint256 debtAmount
    ) public returns (uint256 collAmount, uint256 price) {
        IPriceFeed feed = IPriceFeed(PRISMA_CORE.priceFeed());
        price = feed.fetchPrice(collateral);
        collAmount = (debtAmount * 1e18) / price;
        return (collAmount, price);
    }

    /**
        @notice Update the local storage array of trove managers
        @dev Should be called whenever a trove manager is added
     */
    function syncTroveManagers() public returns (bool) {
        uint256 newLength = factory.troveManagerCount();

        for (uint i = troveManagers.length; i < newLength; i++) {
            ITroveManager troveManager = ITroveManager(factory.troveManagers(i));
            troveManagers.push(troveManager);
        }

        emit TroveManagersSynced();
        return true;
    }

    /**
        @notice Collect accrued interest from all trove managers
        @dev Callable by anyone at any time. Also called within `processWeeklyFees`.
     */
    function collectInterests() public returns (bool) {
        uint256 length = troveManagers.length;
        for (uint i = 0; i < length; i++) {
            ITroveManager tm = troveManagers[i];
            if (tm.interestPayable() > 0) tm.collectInterests();
        }

        emit InterestCollected();
        return true;
    }

    /**
        @notice Process weekly fees
        @dev Callable once per week. The caller is incentivized with a fixed
             amount of debt tokens.
     */
    function processWeeklyFees() external returns (bool) {
        require(getWeek() > updatedWeek, "Already called this week");
        updatedWeek = uint16(getWeek());

        // collect accrued interest this week
        collectInterests();

        // calculate amount of debtToken to distribute
        address receiver = PRISMA_CORE.feeReceiver();
        uint256 amount = debtToken.balanceOf(receiver);
        amount = (amount * maxWeeklyDebtPct) / MAX_PCT;
        uint256 maxDebt = maxWeeklyDebtAmount;
        if (amount > maxDebt) amount = maxDebt;
        debtToken.transferFrom(receiver, address(this), amount);

        // deduct `callerIncentive` from amount
        uint256 incentive = callerIncentive;
        amount -= incentive;

        // add liquidity to `curveLpPool`
        bool addedLiquidity;
        uint256 polPct = weeklyDebtPOLPct;
        if (polPct > 0) {
            if ((curvePoolLp.balanceOf(receiver) * MAX_PCT) / curvePoolLp.totalSupply() < targetPOLPct) {
                uint256 polAmount = (amount * polPct) / MAX_PCT;
                amount -= polAmount;
                polAmount += pendingPOLDebtAmount;

                if (addLiquidityChecker.canAddLiquidity(msg.sender, polAmount)) {
                    uint256 added = _addLiquidity(polAmount, receiver);
                    addedLiquidity = true;
                    pendingPOLDebtAmount = uint88(polAmount - added);
                    emit PendingPOLDebtUpdated(polAmount - added);
                } else {
                    pendingPOLDebtAmount = uint88(polAmount);
                    emit PendingPOLDebtUpdated(polAmount);
                }
            }
        }

        // transfer `callerIncentive` to caller - thank you for your service!
        if (incentive != 0) {
            if (!addedLiquidity) {
                incentive /= 2;
                amount += incentive;
            }
            debtToken.transfer(msg.sender, incentive);
            emit CallerIncentivePaid(msg.sender, incentive);
        }

        // deposit to `feeDistributor`
        if (amount > 0) {
            feeDistributor.depositFeeToken(address(debtToken), amount);
            emit FeeTokenDeposited(amount);
        }

        return true;
    }

    /**
        @notice Add any pending liquidity
        @dev Reverts if the liquidity checker disallows
     */
    function addPendingLiquidity() external returns (bool) {
        uint256 amount = pendingPOLDebtAmount;
        if (amount > 0) {
            require(addLiquidityChecker.canAddLiquidity(msg.sender, amount), "Blocked by liquidityChecker");
            uint added = _addLiquidity(amount, PRISMA_CORE.feeReceiver());
            pendingPOLDebtAmount = uint88(amount - added);
            emit PendingPOLDebtUpdated(amount - added);
        }
        return true;
    }

    function recoverToken(IERC20 token) external onlyOwner returns (bool) {
        uint256 amount = token.balanceOf(address(this));
        if (amount > 0) {
            if (token == debtToken) {
                // if recovering `debtToken`, need to zero pending POL amount or things break
                pendingPOLDebtAmount = 0;
                emit PendingPOLDebtUpdated(0);
            }
            token.safeTransfer(PRISMA_CORE.feeReceiver(), amount);
        }
        return true;
    }

    function _addLiquidity(uint256 debtAmount, address receiver) internal returns (uint256) {
        uint256 priceScale = curvePool.price_scale();

        uint256 prismaAmount = (debtAmount * 1e18) / priceScale;
        uint256 prismaAvailable = prismaToken.balanceOf(receiver);

        // if insufficient PRISMA is available, adjust the amounts
        if (prismaAvailable < prismaAmount) {
            if (prismaAvailable < 1e18) return 0;
            prismaAmount = prismaAvailable;
            debtAmount = (prismaAmount * priceScale) / 1e18;
        }

        prismaToken.transferFrom(receiver, address(this), prismaAmount);
        uint256 lpAmount = curvePool.add_liquidity([debtAmount, prismaAmount], 0, false, receiver);

        emit LiquidityAdded(priceScale, debtAmount, prismaAmount, lpAmount);
        return debtAmount;
    }
}
