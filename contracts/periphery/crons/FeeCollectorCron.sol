//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IRewardDistributor} from "../../interfaces/governance/IRewardDistributor.sol";
import {IWETH} from "../../interfaces/governance/IWETH.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FeeCollectorCron is Initializable, OwnableUpgradeable {
  address public collector;
  address public gelatoooooo;
  address public odos;
  address[] public tokens;

  IRewardDistributor public stakerMahaZai;
  IRewardDistributor public stakerUsdcZai;
  IWETH public weth;

  event EthCollected(uint256 indexed amount);
  event EthDistributed(address indexed to, uint256 indexed amount);

  function init(
    address _weth,
    address _odos,
    address[] memory _tokens,
    address _gelatoooooo,
    address _stakerMahaZai,
    address _stakerUsdcZai,
    address _owner
  ) public reinitializer(6) {
    __Ownable_init(msg.sender);

    weth = IWETH(_weth);
    gelatoooooo = _gelatoooooo;
    stakerMahaZai = IRewardDistributor(_stakerMahaZai);
    stakerUsdcZai = IRewardDistributor(_stakerUsdcZai);

    setTokens(_tokens);
    setOdos(_odos);

    _transferOwnership(_owner);

    weth.approve(_stakerMahaZai, type(uint256).max);
    weth.approve(_stakerUsdcZai, type(uint256).max);
  }

  receive() external payable {
    weth.deposit{value: msg.value}();
  }

  function setOdos(address _odos) public onlyOwner {
    odos = _odos;
  }

  function balances() public view returns (uint256[] memory, address[] memory) {
    uint256[] memory amounts = new uint256[](tokens.length);

    for (uint i = 0; i < tokens.length; i++) {
      amounts[i] = IERC20(tokens[i]).balanceOf(address(this));
    }

    return (amounts, tokens);
  }

  function setTokens(address[] memory _tokens) public onlyOwner {
    tokens = _tokens;
    approve();
  }

  function approve() public {
    for (uint i = 0; i < tokens.length; i++) {
      IERC20(tokens[i]).approve(odos, type(uint256).max);
    }
  }

  function swap(bytes memory data) public {
    require(msg.sender == owner() || msg.sender == gelatoooooo, "who dis?");

    // swap on odos
    (bool success, ) = odos.call(data);
    require(success, "odos call failed");

    // send all weth to the destination
    uint256 amt = weth.balanceOf(address(this));

    uint256 ownerAmt = amt / 3; // give 33% to the owner
    uint256 zaiMahaAmt = amt / 3; // 33% to ZAI/MAHA staking
    uint256 zaiUsdcAmt = amt - ownerAmt - zaiMahaAmt; // 33% to ZAI/USDC staking

    weth.transfer(owner(), ownerAmt);
    stakerMahaZai.notifyRewardAmount(zaiMahaAmt);
    stakerUsdcZai.notifyRewardAmount(zaiUsdcAmt);

    // emit events
    emit EthCollected(amt);
    emit EthDistributed(owner(), ownerAmt);
    emit EthDistributed(address(stakerMahaZai), zaiMahaAmt);
    emit EthDistributed(address(stakerUsdcZai), zaiUsdcAmt);
  }

  function refund(IERC20 token) public onlyOwner {
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }
}
