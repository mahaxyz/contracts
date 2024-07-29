// import
import { ethers } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/core/ZaiStablecoin.sol/ZaiStablecoin.json";

const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const factoryAddress = "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0";
const constructorArgs: any[] = ["0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b"];

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
