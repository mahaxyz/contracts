// import
import { ethers } from "ethers";
import { getCreate2Address } from "./create2";

// declare deployment parameters
import contractArtifact from "../artifacts/contracts/core/ZaiStablecoin.sol/ZaiStablecoin.json";

const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

export const factoryAddress = "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3";
const constructorArgs: any[] = ["0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572"];

console.log("constructor parameters", constructorTypes, constructorArgs);

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id("" + i);
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
