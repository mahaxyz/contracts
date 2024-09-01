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

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/// @title MorphoFixedPriceOracleProxy
/// @author maha.xyz
/// @notice A contract that returns a fixed price for morpho;
contract MorphoFixedPriceOracleProxy is Initializable {
  uint256 private _price;
  uint256 private _decimals;

  function getPrice() public view returns (uint256 price_) {
    price_ = _price;
  }

  function initialize(uint256 price_, uint8 decimals_) external initializer {
    _price = price_;
    _decimals = decimals_;
  }

  function getPriceFor(uint256 amount) public view returns (uint256) {
    return (_price * amount) / (1 * 10 ** _decimals);
  }

  /// Returns the price of 1 asset of collateral token quoted in 1 asset of loan token, scaled by 1e36.
  function price() external view returns (uint256 price_) {
    price_ = _price * 1e36 / (1 * 10 ** _decimals);
  }
}
