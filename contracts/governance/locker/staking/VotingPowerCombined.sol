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

import {IOmnichainStaking} from "../../../interfaces/governance/IOmnichainStaking.sol";
import {IPoolVoter} from "../../../interfaces/governance/IPoolVoter.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IVotes} from "@openzeppelin/contracts/governance/utils/IVotes.sol";

// TODO: Write LayerZero functions over here

contract VotingPowerCombined is IVotes, OwnableUpgradeable {
  IOmnichainStaking public lpStaking;
  IOmnichainStaking public tokenStaking;
  IPoolVoter public voter;

  function init(address _owner, address _tokenStaking, address _lpStaking, address _voter) external reinitializer(1) {
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
    if (address(lpStaking) == address(0) || address(tokenStaking) == address(0)) {
      return 0;
    } else if (address(lpStaking) == address(0)) {
      return tokenStaking.getVotes(account);
    } else if (address(tokenStaking) == address(0)) {
      return lpStaking.getVotes(account);
    }
    return lpStaking.getVotes(account) + tokenStaking.getVotes(account);
  }

  function totalVotes() external view returns (uint256) {
    if (address(lpStaking) == address(0) || address(tokenStaking) == address(0)) {
      return 0;
    } else if (address(lpStaking) == address(0)) {
      return tokenStaking.totalVotes();
    } else if (address(tokenStaking) == address(0)) {
      return lpStaking.totalVotes();
    }

    return lpStaking.totalVotes() + tokenStaking.totalVotes();
  }

  function getPastVotes(address account, uint256 timepoint) external view returns (uint256) {
    if (address(lpStaking) == address(0) || address(tokenStaking) == address(0)) {
      return 0;
    } else if (address(lpStaking) == address(0)) {
      return tokenStaking.getPastVotes(account, timepoint);
    } else if (address(tokenStaking) == address(0)) {
      return lpStaking.getPastVotes(account, timepoint);
    }
    return lpStaking.getPastVotes(account, timepoint) + tokenStaking.getPastVotes(account, timepoint);
  }

  function reset(address _who) external {
    require(
      msg.sender == _who || msg.sender == address(lpStaking) || msg.sender == address(tokenStaking),
      "invalid reset performed"
    );
    if (address(voter) != address(0)) voter.reset(_who);
  }

  function getPastTotalSupply(uint256 timepoint) external view returns (uint256) {
    if (address(lpStaking) == address(0) || address(tokenStaking) == address(0)) {
      return 0;
    } else if (address(lpStaking) == address(0)) {
      return tokenStaking.getPastTotalSupply(timepoint);
    } else if (address(tokenStaking) == address(0)) {
      return lpStaking.getPastTotalSupply(timepoint);
    }
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
