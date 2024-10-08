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

contract Deployer {
  event Deploy(address addr);

  function deploy(bytes memory bytecode, uint256 _salt) external {
    address addr;
    assembly {
      addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
      if iszero(extcodesize(addr)) { revert(0, 0) }
    }

    emit Deploy(addr);
  }

  function deployWithAssert(bytes memory bytecode, uint256 _salt, address target) external {
    address addr;
    assembly {
      addr := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)
      if iszero(extcodesize(addr)) { revert(0, 0) }
    }

    require(addr == target, "Deployer: INVALID_TARGET");

    emit Deploy(addr);
  }
}
