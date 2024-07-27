// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.20;

import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {IERC1967} from "@openzeppelin/contracts/interfaces/IERC1967.sol";

/**
 * @dev Interface for {MAHAProxy}. In order to implement transparency, {MAHAProxy}
 * does not implement this interface directly, and its upgradeability mechanism is implemented by an internal dispatch
 * mechanism. The compiler is unaware that these functions are implemented by {MAHAProxy} and will not
 * include them in the ABI so this interface must be used to interact with it.
 */
interface IMAHAProxy is IERC1967 {
  function upgradeToAndCall(address, bytes calldata) external payable;
}

contract MAHAProxy is ERC1967Proxy {
  // An immutable address for the admin to avoid unnecessary SLOADs before each call
  // at the expense of removing the ability to change the admin once it's set.
  // This is acceptable if the admin is always a ProxyAdmin instance or similar contract
  // with its own ability to transfer the permissions to another account.
  address private immutable _admin;

  /**
   * @dev The proxy caller is the current admin, and can't fallback to the proxy target.
   */
  error ProxyDeniedAdminAccess();

  constructor(
    address logic_,
    address admin_,
    bytes memory data_
  ) payable ERC1967Proxy(logic_, data_) {
    _admin = admin_;
    ERC1967Utils.changeAdmin(proxyAdmin());
  }

  /**
   * @dev Returns the admin of this proxy.
   */
  function proxyAdmin() public view virtual returns (address) {
    return _admin;
  }

  /**
   * @dev Returns the implementation address of the proxy.
   */
  function implementation() public view virtual returns (address) {
    return _implementation();
  }

  /**
   * @dev If caller is the admin process the call internally, otherwise transparently fallback to the proxy behavior.
   */
  function _fallback() internal virtual override {
    if (msg.sender == proxyAdmin()) {
      if (msg.sig != IMAHAProxy.upgradeToAndCall.selector) {
        revert ProxyDeniedAdminAccess();
      } else {
        _dispatchUpgradeToAndCall();
      }
    } else {
      super._fallback();
    }
  }

  /**
   * @dev Upgrade the implementation of the proxy. See {ERC1967Utils-upgradeToAndCall}.
   *
   * Requirements:
   *
   * - If `data` is empty, `msg.value` must be zero.
   */
  function _dispatchUpgradeToAndCall() private {
    (address newImplementation, bytes memory data) = abi.decode(
      msg.data[4:],
      (address, bytes)
    );
    ERC1967Utils.upgradeToAndCall(newImplementation, data);
  }
}
