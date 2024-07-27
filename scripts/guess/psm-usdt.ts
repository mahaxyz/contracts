// import
import { ethers } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";
import implArtificat from "../../artifacts/contracts/core/psm/PegStabilityModule.sol/PegStabilityModule.json";

// @ts-ignore
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const impl = new ethers.Contract(
  "0xC17596890598282dE86028B24C0C4885a9261874",
  implArtificat.abi
);

const initData = impl.interface.encodeFunctionData("initialize", [
  "0x6900057428C99Fb373397D657Beb40D92D8aC97f", // address _zai,
  "0xdac17f958d2ee523a2206206994597c13d831ec7", // address _collateral,
  "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572", // address _governance,
  1e6, // uint256 _newRate,
  100000000n * 10n ** 6n, // uint256 _supplyCap,
  100000000n * 10n ** 18n, // uint256 _debtCap,
  0, // uint256 _mintFeeBps,
  300, // uint256 _redeemFeeBps,
  "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
]);

const factoryAddress = "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3";
const constructorArgs: any[] = [
  "0xC17596890598282dE86028B24C0C4885a9261874", // implementation
  "0x69000f2f879ee598ddf16c6c33cfc4f2d983b6bd", // proxyadmin
  initData, // init data
];

console.log("constructor parameters", constructorTypes, constructorArgs);

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id("#" + i);
    // Calculate contract address
    const computedAddress = getCreate2Address({
      salt: salt,

      factoryAddress,
      contractBytecode: contractArtifact.bytecode,
      constructorTypes: constructorTypes,
      constructorArgs: constructorArgs,
    });

    if (computedAddress.startsWith("0x69000")) {
      console.log("found the right salt hash");
      console.log("salt", salt, computedAddress);
      break;
    }

    if (i % 100000 == 0) console.log(i, "salt", salt, computedAddress);
    i++;
  }
};

job();
