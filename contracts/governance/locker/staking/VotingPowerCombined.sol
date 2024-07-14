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

import {IOmnichainStaking} from "../../../interfaces/governance/IOmnichainStaking.sol";
import {IPoolVoter} from "../../../interfaces/governance/IPoolVoter.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

// TODO: Write LayerZero functions over here

contract VotingPowerCombined is IVotes, OwnableUpgradeable {
  IOmnichainStaking public lpStaking;
  IOmnichainStaking public tokenStaking;
  IPoolVoter public voter;

  function init(address _owner, address _tokenStaking, address _lpStaking, address _voter) external reinitializer(2) {
    lpStaking = IOmnichainStaking(_lpStaking);
    tokenStaking = IOmnichainStaking(_tokenStaking);
    voter = IPoolVoter(_voter);
    __Ownable_init(_owner);
  }

  function setAddresses(address _tokenStaking, address _lpStaking, address _voter) external onlyOwner {
    lpStaking = IOmnichainStaking(_lpStaking);
    tokenStaking = IOmnichainStaking(_tokenStaking);
    voter = IPoolVoter(_voter);
  }

  function getVotes(address account) external view returns (uint256) {
    return lpStaking.getVotes(account) + tokenStaking.getVotes(account);
  }

  function getPastVotes(address account, uint256 timepoint) external view returns (uint256) {
    return lpStaking.getPastVotes(account, timepoint) + tokenStaking.getPastVotes(account, timepoint);
  }

  function reset(address _who) external {
    require(msg.sender == _who || msg.sender == address(lpStaking) || msg.sender == address(tokenStaking), "invalid reset performed");
    voter.reset(_who);
  }

  function getPastTotalSupply(uint256 timepoint) external view returns (uint256) {
    return lpStaking.getPastTotalSupply(timepoint) + tokenStaking.getPastTotalSupply(timepoint);
  }

  function delegates(address) external pure override returns (address) {
    require(false, "delegate set at the staking level");
    return address(0);
  }

  function delegate(address) external pure override {
    require(false, "delegate set at the staking level");
  }

  function delegateBySig(address, uint256, uint256, uint8, bytes32, bytes32) external pure override {
    require(false, "delegate set at the staking level");
  }
}
