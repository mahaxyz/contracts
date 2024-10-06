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

import {IStargate} from "../../interfaces/periphery/layerzero/IStargate.sol";
import {IOFT, MessagingFee, SendParam} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/interfaces/IOFT.sol";

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IL1BridgeCollateralL0 {
  function process() external;
}

contract L1RestakingSweeperCron is OwnableUpgradeable {
  address public gelatoooooo;
  address public usdc;
  uint256 public limit;
  IL1BridgeCollateralL0 public depositCollateralL0;

  function initialize(
    address _usdc,
    uint256 _limit,
    address _depositCollateralL0,
    address _governance
  ) public reinitializer(1) {
    __Ownable_init(msg.sender);

    usdc = _usdc;
    limit = _limit;
    depositCollateralL0 = IL1BridgeCollateralL0(_depositCollateralL0);

    _transferOwnership(_governance);
  }

  receive() external payable {
    // nothing
  }

  function setSweepLimit(uint256 _limit) public onlyOwner {
    limit = _limit;
  }

  function usdcToSweep() public view returns (uint256) {
    return IERC20(usdc).balanceOf(address(depositCollateralL0));
  }

  function shouldExecute() public view returns (bool) {
    return usdcToSweep() >= limit;
  }

  function execute() public payable {
    require(msg.sender == owner() || msg.sender == gelatoooooo, "who dis?");
    IERC20(usdc).balanceOf(address(depositCollateralL0));
    depositCollateralL0.process();
  }

  function refundETH() public onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }
}
