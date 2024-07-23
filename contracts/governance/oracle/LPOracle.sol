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

// import "../interfaces/INileAMM.sol";
// import "../../interfaces/IAggregatorV3Interface.sol";

/// @title LPOracle
/// @notice This contract provides a price oracle for the liquidity pool tokens in a Nile AMM.
/// @dev This contract interacts with the INileAMM interface to fetch reserves and calculate prices.
/// @dev Reference from
/// https://github.com/AlphaFinanceLab/alpha-homora-v2-contract/blob/master/contracts/oracle/UniswapV2Oracle.sol
contract LPOracle {
// INileAMM public immutable nileAMM;
// IAggregatorV3Interface public immutable zeroPriceFeed;
// IAggregatorV3Interface public immutable ethPriceFeed;
// /// @notice Constructor sets the address of the Nile AMM contract.
// /// @param _nileAMM The address of the Nile AMM contract.
// constructor(
//     address _nileAMM,
//     address _zeroPriceFeed,
//     address _ethPriceFeed
// ) {
//     nileAMM = INileAMM(_nileAMM);
//     zeroPriceFeed = IAggregatorV3Interface(_zeroPriceFeed);
//     ethPriceFeed = IAggregatorV3Interface(_ethPriceFeed);
// }
// /// @notice Gets the price of the liquidity pool token.
// /// @dev This function fetches reserves from the Nile AMM and uses a pre-defined price for tokens to calculate the LP
// token price.
// /// @return price The price of the liquidity pool token.
// function getPrice() public view returns (uint256 price) {
//     (uint256 reserve0, uint256 reserve1, ) = nileAMM.getReserves();
//     int256 px0 = zeroPriceFeed.latestAnswer();
//     int256 px1 = ethPriceFeed.latestAnswer();
//     require(px0 > 0 && px1 > 0, "Invalid Price");
//     uint256 sqrtK = (sqrt(reserve0 * reserve1) * 1e18) /
//         nileAMM.totalSupply();
//     price = (sqrtK * 2 * sqrt(uint256(px0 * px1))) / 1e18;
// }
// /// @notice Computes the square root of a given number using the Babylonian method.
// /// @dev This function uses an iterative method to compute the square root of a number.
// /// @param x The number to compute the square root of.
// /// @return y The square root of the given number.
// function sqrt(uint x) public pure returns (uint y) {
//     if (x == 0) return 0; // Handle the edge case for 0
//     uint z = (x + 1) / 2;
//     y = x;
//     while (z < y) {
//         y = z;
//         z = (x / z + z) / 2;
//     }
// }
}
