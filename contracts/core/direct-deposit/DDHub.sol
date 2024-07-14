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

import {AccessControlEnumerable} from "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import {IZaiStablecoin} from "../../interfaces/IZaiStablecoin.sol";
import {IDDHub} from "../../interfaces/core/IDDHub.sol";
import {IDDPool} from "../../interfaces/core/IDDPool.sol";
import {IDDPlan} from "../../interfaces/core/IDDPlan.sol";
import {Math} from "./Math.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title Direct Deposit Hub
 * @author maha.xyz
 * @notice This is the main contract responsible for managing pools.
 */
contract DDHub is Math, IDDHub, ReentrancyGuard {
    IZaiStablecoin public zai;

    // --- Auth ---
    /**
     * @notice Maps address that have permission in the Pool.
     * @dev 1 = allowed, 0 = no permission
     * @return authorization 1 or 0
     */
    mapping(address => uint256) public wards;

    address public vow;
    // EndLike public end;
    uint256 public locked;

    /// @notice maps ilk bytes32 to the D3M tracking struct.
    mapping(bytes32 => Ilk) public ilks;

    /**
     * @dev sets msg.sender as authed.
     * @param daiJoin_ address of the DSS Dai Join contract
     */
    constructor(address daiJoin_) {
        daiJoin = DaiJoinLike(daiJoin_);
        vat = VatLike(daiJoin.vat());
        TokenLike(daiJoin.dai()).approve(daiJoin_, type(uint256).max);
        vat.hope(daiJoin_);

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /// @notice Modifier will revoke if msg.sender is not authorized.
    modifier auth() {
        require(wards[msg.sender] == 1, "D3MHub/not-authorized");
        _;
    }

    // --- Administration ---
    /// @inheritdoc IDDHub
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /// @inheritdoc IDDHub
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /// @inheritdoc IDDHub
    function file(bytes32 what, address data) external auth {
        require(vat.live() == 1, "D3MHub/no-file-during-shutdown");

        if (what == "vow") vow = data;
        else if (what == "end") end = EndLike(data);
        else revert("D3MHub/file-unrecognized-param");
        emit File(what, data);
    }

    /// @inheritdoc IDDHub
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "tau") ilks[ilk].tau = data;
        else revert("D3MHub/file-unrecognized-param");

        emit File(ilk, what, data);
    }

    /// @inheritdoc IDDHub
    function file(bytes32 ilk, bytes32 what, address data) external auth {
        require(vat.live() == 1, "D3MHub/no-file-during-shutdown");
        require(ilks[ilk].tic == 0, "D3MHub/pool-not-live");

        if (what == "pool") ilks[ilk].pool = IDDPool(data);
        else if (what == "plan") ilks[ilk].plan = ID3MPlan(data);
        else revert("D3MHub/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    // --- Internal functions that are called from exec(bytes32 ilk) ---

    function _wipe(bytes32 ilk, IDDPool _pool, address urn) internal {
        uint256 amount = _pool.maxWithdraw();
        if (amount > 0) {
            _pool.withdraw(amount);
            daiJoin.join(address(this), amount);
            vat.move(address(this), vow, amount * RAY);

            uint256 toSlip = _min(vat.gem(ilk, urn), amount);
            // amount bounds toSlip and amount * RAY bounds amount to be much less than MAXINT256
            vat.slip(ilk, urn, -int256(toSlip));
            emit Unwind(ilk, amount);
        } else {
            emit NoOp(ilk);
        }
    }

    function _exec(
        bytes32 ilk,
        IDDPool _pool,
        uint256 Art,
        uint256 lineWad
    ) internal {
        require(lineWad <= SAFEMAX, "D3MHub/lineWad-above-max-safe");
        (uint256 ink, uint256 art) = vat.urns(ilk, address(_pool));
        require(ink <= SAFEMAX, "D3MHub/ink-above-max-safe");
        require(ink >= art, "D3MHub/ink-not-greater-equal-art");
        require(art == Art, "D3MHub/more-than-one-urn");
        uint256 currentAssets = _pool.assetBalance(); // Should return DAI owned by D3MPool
        uint256 maxWithdraw = _min(_pool.maxWithdraw(), SAFEMAX);

        // Determine if fees were generated and try to account them (or the most that it is possible)
        if (currentAssets > ink) {
            uint256 fixInk = _min(
                _min(
                    currentAssets - ink, // fees generated
                    ink < lineWad // if previously CDP was under debt ceiling
                        ? (lineWad - ink) + maxWithdraw // up to gap to reach debt ceiling + maxWithdraw
                        : maxWithdraw // up to maxWithdraw
                ),
                SAFEMAX + art - ink //  ensures that fixArt * RAY (rate) will be <= MAXINT256 (in vat.grab)
            );
            vat.slip(ilk, address(_pool), int256(fixInk)); // Generate extra collateral
            vat.frob(
                ilk,
                address(_pool),
                address(_pool),
                address(this),
                int256(fixInk),
                0
            ); // Lock it
            unchecked {
                ink += fixInk; // can not overflow as worst case will be the value of currentAssets
            }
            emit Fees(ilk, fixInk);
        }
        // Get the DAI and send as surplus (if there was permissionless DAI paid or fees accounted)
        if (art < ink) {
            address _vow = vow;
            uint256 fixArt;
            unchecked {
                fixArt = ink - art; // Amount of fees + permissionless DAI paid we will now transform to debt
            }
            art = ink;
            vat.suck(_vow, _vow, fixArt * RAY); // This needs to be done to make sure we can deduct sin[vow] and vice in the next call
            // No need for `fixArt <= MAXINT256` require as:
            // MAXINT256 >>> MAXUINT256 / RAY which is already restricted above
            // Also fixArt should be always <= SAFEMAX (MAXINT256 / RAY)
            vat.grab(
                ilk,
                address(_pool),
                address(_pool),
                _vow,
                0,
                int256(fixArt)
            ); // Generating the debt
        }

        // Determine if it needs to unwind or wind
        uint256 toUnwind;
        uint256 toWind;

        // Determine if it needs to fully unwind due to D3M ilk being caged (but not culled), plan is not active or something
        // wrong is going with the third party and we are entering in the ilegal situation of having less assets than registered
        // It's adding up `WAD` due possible rounding errors
        if (
            ilks[ilk].tic != 0 ||
            !ilks[ilk].plan.active() ||
            currentAssets + WAD < ink
        ) {
            toUnwind = maxWithdraw;
        } else {
            uint256 Line = vat.Line();
            uint256 debt = vat.debt();
            uint256 targetAssets = ilks[ilk].plan.getTargetAssets(
                currentAssets
            );

            // Determine if it needs to unwind due to:
            unchecked {
                toUnwind = _max(
                    _max(
                        art > lineWad ? art - lineWad : 0, // ilk debt ceiling exceeded
                        debt > Line ? _divup(debt - Line, RAY) : 0 // global debt ceiling exceeded
                    ),
                    targetAssets < currentAssets
                        ? currentAssets - targetAssets
                        : 0 // plan targetAssets
                );
                if (toUnwind > 0) {
                    toUnwind = _min(toUnwind, maxWithdraw);
                } else {
                    // Determine up to which value to wind:
                    // subtractions are safe as otherwise toUnwind > 0 conditional would be true
                    toWind = _min(
                        _min(
                            _min(
                                lineWad - art, // amount to reach ilk debt ceiling
                                (Line - debt) / RAY // amount to reach global debt ceiling
                            ),
                            targetAssets - currentAssets // plan targetAssets
                        ),
                        _pool.maxDeposit() // restricts winding if the pool has a max deposit
                    );
                }
            }
        }

        if (toUnwind > 0) {
            _pool.withdraw(toUnwind);
            daiJoin.join(address(this), toUnwind);
            // SAFEMAX bounds toUnwind making sure is <<< than MAXINT256
            vat.frob(
                ilk,
                address(_pool),
                address(_pool),
                address(this),
                -int256(toUnwind),
                -int256(toUnwind)
            );
            vat.slip(ilk, address(_pool), -int256(toUnwind));
            emit Unwind(ilk, toUnwind);
        } else if (toWind > 0) {
            require(art + toWind <= SAFEMAX, "D3MHub/wind-overflow");
            vat.slip(ilk, address(_pool), int256(toWind));
            vat.frob(
                ilk,
                address(_pool),
                address(_pool),
                address(this),
                int256(toWind),
                int256(toWind)
            );
            daiJoin.exit(address(_pool), toWind);
            _pool.deposit(toWind);
            emit Wind(ilk, toWind);
        } else {
            emit NoOp(ilk);
        }
    }

    /// @inheritdoc IDDHub
    function exec(bytes32 ilk) external nonReentrant {
        // IMPORTANT: this function assumes Vat rate of D3M ilks will always be == 1 * RAY (no fees).
        // That's why this module converts normalized debt (art) to Vat DAI generated with a simple RAY multiplication or division

        (uint256 Art, uint256 rate, uint256 spot, uint256 line, ) = vat.ilks(
            ilk
        );
        require(rate == RAY, "D3MHub/rate-not-one");
        require(spot == RAY, "D3MHub/spot-not-one");

        IDDPool _pool = ilks[ilk].pool;

        _pool.preDebtChange();

        if (vat.live() == 0) {
            // MCD caged
            // The main reason to have this case is trying to unwind the highest amount of DAI from the pool before end.debt is established.
            // That has the advantage to simplify End process, the best scenario would be unwinding everything which will decrease to the
            // minimum the amount of circulating supply of DAI, giving directly more value of other collaterals for each unit of DAI.
            // If this is not called, anyone can still call end.skim permissionlesly at any moment leaving remaining amount of pool shares
            // available to DAI holders to redeem it. This type of collateral is a cyclical one though, where user will need to go from
            // DAI -> pool share -> DAI -> ... making it not the most practical to handle. However, at the end, the net value of other
            // collaterals received per unit of DAI should end up being the same one (assuming there is liquidity in the pool to withdraw).
            EndLike _end = end;
            require(_end.debt() == 0, "D3MHub/end-debt-already-set");
            require(
                ilks[ilk].culled == 0,
                "D3MHub/module-has-to-be-unculled-first"
            );
            _end.skim(ilk, address(_pool));
            _wipe(ilk, _pool, address(_end));
        } else if (ilks[ilk].culled == 1) {
            _wipe(ilk, _pool, address(_pool));
        } else {
            _exec(
                ilk,
                _pool,
                Art,
                line / RAY // round down ilk line in wad format
            );
        }

        _pool.postDebtChange();
    }

    /// @inheritdoc IDDHub
    function exit(bytes32 ilk, address usr, uint256 wad) external nonReentrant {
        require(wad <= MAXINT256, "D3MHub/overflow");
        vat.slip(ilk, msg.sender, -int256(wad));
        ilks[ilk].pool.exit(usr, wad);
        emit Exit(ilk, usr, wad);
    }

    /// @inheritdoc IDDHub
    function cage(bytes32 ilk) external auth {
        require(vat.live() == 1, "D3MHub/no-cage-during-shutdown");
        require(ilks[ilk].tic == 0, "D3MHub/pool-already-caged");

        ilks[ilk].tic = block.timestamp + ilks[ilk].tau;
        emit Cage(ilk);
    }

    /// @inheritdoc IDDHub
    function cull(bytes32 ilk) external {
        require(vat.live() == 1, "D3MHub/no-cull-during-shutdown");

        uint256 _tic = ilks[ilk].tic;
        require(_tic > 0, "D3MHub/pool-live");

        require(
            _tic <= block.timestamp || wards[msg.sender] == 1,
            "D3MHub/unauthorized-cull"
        );
        require(ilks[ilk].culled == 0, "D3MHub/already-culled");

        IDDPool _pool = ilks[ilk].pool;

        (uint256 ink, uint256 art) = vat.urns(ilk, address(_pool));
        require(ink <= MAXINT256, "D3MHub/overflow");
        require(art <= MAXINT256, "D3MHub/overflow");
        vat.grab(
            ilk,
            address(_pool),
            address(_pool),
            vow,
            -int256(ink),
            -int256(art)
        );

        ilks[ilk].culled = 1;
        emit Cull(ilk, ink, art);
    }

    /// @inheritdoc IDDHub
    function uncull(bytes32 ilk) external {
        IDDPool _pool = ilks[ilk].pool;

        require(ilks[ilk].culled == 1, "D3MHub/not-prev-culled");
        require(vat.live() == 0, "D3MHub/no-uncull-normal-operation");

        address _vow = vow;
        uint256 wad = vat.gem(ilk, address(_pool));
        vat.suck(_vow, _vow, wad * RAY); // This needs to be done to make sure we can deduct sin[vow] and vice in the next call
        // wad * RAY bounds wad to be much less than MAXINT256
        vat.grab(
            ilk,
            address(_pool),
            address(_pool),
            _vow,
            int256(wad),
            int256(wad)
        );

        ilks[ilk].culled = 0;
        emit Uncull(ilk, wad);
    }

    /// @inheritdoc IDDHub
    function pool(bytes32 ilk) external view returns (address) {
        return address(ilks[ilk].pool);
    }

    /// @inheritdoc IDDHub
    function plan(bytes32 ilk) external view returns (address) {
        return address(ilks[ilk].plan);
    }

    /// @inheritdoc IDDHub
    function tau(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].tau;
    }

    /// @inheritdoc IDDHub
    function culled(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].culled;
    }

    /// @inheritdoc IDDHub
    function tic(bytes32 ilk) external view returns (uint256) {
        return ilks[ilk].tic;
    }
}
