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

import {DDBase, IDDPool} from "./DDBase.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IPool {
  function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function withdraw(address asset, uint256 amount, address to) external;
}

/**
 * @title ZeroLend Direct Deposit Module
 * @author maha.xyz
 * @notice A direct deposit module that deposits into ZeroLend directly
 */
contract DDZeroLendV1 is Initializable, DDBase {
  IPool public pool;
  IERC20 public z0USDz;

  function initialize(address _hub, address _zai, address _pool, address _z0USDz) external reinitializer(1) {
    __DDBBase_init(_zai, _hub);

    pool = IPool(_pool);
    z0USDz = IERC20(_z0USDz);

    require(_hub != address(0), "DDZeroLend/zero-address");
    require(_zai != address(0), "DDZeroLend/zero-address");
    require(_pool != address(0), "DDZeroLend/zero-address");

    zai.approve(_pool, type(uint256).max);
  }

  /// @inheritdoc IDDPool
  function deposit(uint256 wad) external override onlyHub {
    zai.transferFrom(msg.sender, me, wad);
    pool.supply(address(zai), wad, me, 0);
  }

  /// @inheritdoc IDDPool
  function withdraw(uint256 wad) external override onlyHub {
    uint256 prevDai = zai.balanceOf(msg.sender);
    pool.withdraw(address(zai), wad, msg.sender);
    require(zai.balanceOf(msg.sender) == prevDai + wad, "DDZeroLend/incorrect-zai-balance-received");
  }

  /// @inheritdoc IDDPool
  function preDebtChange() external override {
    // nothing
  }

  /// @inheritdoc IDDPool
  function postDebtChange() external override {
    // nothing
  }

  /// @inheritdoc IDDPool
  function assetBalance() public view returns (uint256) {
    return z0USDz.balanceOf(me);
  }

  /// @inheritdoc IDDPool
  function maxDeposit() external pure returns (uint256) {
    return type(uint256).max; // todo check the supply cap
  }

  /// @inheritdoc IDDPool
  function maxWithdraw() external view returns (uint256) {
    return _min(zai.balanceOf(address(z0USDz)), assetBalance());
  }

  /// @inheritdoc IDDPool
  function redeemable() external view returns (address) {
    return address(z0USDz);
  }

  function _min(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = x <= y ? x : y;
  }
}
