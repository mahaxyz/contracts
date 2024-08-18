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

import {IOptimismMintableERC20} from "../../interfaces/periphery/IOptimismMintableERC20.sol";
import {XERC20} from "./XERC20.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";

contract XERC20Optimism is ERC165Upgradeable, XERC20, IOptimismMintableERC20 {
  /**
   * @notice The address of the l1 token (remoteToken)
   */
  address public l1Token;

  /**
   * @notice The address of the optimism canonical bridge
   */
  address public optimismBridge;

  /**
   * @notice Constructs the initial config of the XERC20
   * @param _name The name of the token
   * @param _symbol The symbol of the token
   * @param _factory The factory which deployed this contract
   */
  function initialize(
    string memory _name,
    string memory _symbol,
    address _factory,
    address _l1Token,
    address _optimismBridge
  ) public initializer {
    __ERC165_init();
    __XERC20_init(_name, _symbol, _factory);
    l1Token = _l1Token;
    optimismBridge = _optimismBridge;
  }

  function supportsInterface(bytes4 interfaceId) public view override (ERC165Upgradeable) returns (bool) {
    return interfaceId == type(IOptimismMintableERC20).interfaceId || super.supportsInterface(interfaceId);
  }

  function remoteToken() public view override returns (address) {
    return l1Token;
  }

  function bridge() public view override returns (address) {
    return optimismBridge;
  }

  function mint(address _to, uint256 _amount) public override (XERC20, IOptimismMintableERC20) {
    XERC20.mint(_to, _amount);
  }

  function burn(address _from, uint256 _amount) public override (XERC20, IOptimismMintableERC20) {
    XERC20.burn(_from, _amount);
  }
}
