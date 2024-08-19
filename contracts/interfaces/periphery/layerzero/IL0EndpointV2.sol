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

struct SetConfigParam {
  uint32 eid;
  uint32 configType;
  bytes config;
}

interface IL0EndpointV2 {
  function delegates(address) external view returns (address);
  function setConfig(address, address, SetConfigParam[] calldata) external;
  function skip(
    address _oapp, //the Oapp address
    uint32 _srcEid, //source chain endpoint id
    bytes32 _sender, //the byte32 format of sender address
    uint64 _nonce // the message nonce you wish to skip to
  ) external;
}
