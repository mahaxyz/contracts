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

import {IMultiStakingRewardsERC4626} from "../../interfaces/core/IMultiStakingRewardsERC4626.sol";
import {IWETH} from "../../interfaces/governance/IWETH.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract ZaiFeeCollectorCron is OwnableUpgradeable {
  address public collector;
  address public gelatoooooo;
  address public odos;
  address[] public tokens;

  IMultiStakingRewardsERC4626 public safetyPoolZai;
  IMultiStakingRewardsERC4626 public stakerMahaZai;
  IMultiStakingRewardsERC4626 public stakerUsdcZai;

  IWETH public weth;
  IERC20 public rewardToken;
  address public treasury;

  event RevenueCollected(uint256 indexed amount);
  event EthCollected(uint256 indexed amount);
  event RevenueDistributed(address indexed to, uint256 indexed amount);

  function init(
    address _rewardToken,
    address _weth,
    address _odos,
    address[] memory _tokens,
    address _gelatoooooo,
    address _stakerMahaZai,
    address _stakerUsdcZai,
    address _safetyPoolZai,
    address _governance
  ) public reinitializer(1) {
    __Ownable_init(msg.sender);

    weth = IWETH(_weth);
    rewardToken = IERC20(_rewardToken);
    gelatoooooo = _gelatoooooo;
    safetyPoolZai = IMultiStakingRewardsERC4626(_safetyPoolZai);
    stakerMahaZai = IMultiStakingRewardsERC4626(_stakerMahaZai);
    stakerUsdcZai = IMultiStakingRewardsERC4626(_stakerUsdcZai);

    setTokens(_tokens);
    setOdos(_odos);

    rewardToken.approve(_stakerMahaZai, type(uint256).max);
    rewardToken.approve(_stakerUsdcZai, type(uint256).max);
    rewardToken.approve(_safetyPoolZai, type(uint256).max);

    _transferOwnership(_governance);
  }

  receive() external payable {
    weth.deposit{value: msg.value}();
    emit EthCollected(msg.value);
  }

  function setOdos(address _odos) public onlyOwner {
    odos = _odos;
  }

  function balances() public view returns (uint256[] memory, address[] memory) {
    uint256[] memory amounts = new uint256[](tokens.length);

    for (uint256 i = 0; i < tokens.length; i++) {
      amounts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }

    return (amounts, tokens);
  }

  function setTokens(address[] memory _tokens) public onlyOwner {
    tokens = _tokens;
    approve();
  }

  function approve() public {
    for (uint256 i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).approve(odos, type(uint256).max);
    }
  }

  function swap(bytes memory data) public {
    require(msg.sender == owner() || msg.sender == gelatoooooo, "who dis?");

    // swap on odos
    (bool success,) = odos.call(data);
    require(success, "odos call failed");

    // send all rewardToken to the destination
    uint256 amt = rewardToken.balanceOf(address(this));

    uint256 treasuryAmt = amt / 10; // give 10% to the treasury
    uint256 zaiMahaAmt = amt / 5; // 20% to ZAI/MAHA staking
    uint256 zaiSafetyPoolAmt = amt / 10; // give 10% to ZAI stability pool
    uint256 zaiUsdcAmt = amt - treasuryAmt - zaiMahaAmt - zaiSafetyPoolAmt; // 60% to ZAI/USDC staking

    rewardToken.transfer(treasury, treasuryAmt);
    stakerMahaZai.notifyRewardAmount(rewardToken, zaiMahaAmt);
    stakerUsdcZai.notifyRewardAmount(rewardToken, zaiUsdcAmt);
    safetyPoolZai.notifyRewardAmount(rewardToken, zaiSafetyPoolAmt);

    // emit events
    emit RevenueCollected(amt);
    emit RevenueDistributed(treasury, treasuryAmt);
    emit RevenueDistributed(address(stakerMahaZai), zaiMahaAmt);
    emit RevenueDistributed(address(safetyPoolZai), zaiSafetyPoolAmt);
    emit RevenueDistributed(address(stakerUsdcZai), zaiUsdcAmt);
  }

  function refund(IERC20 token) public onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}
