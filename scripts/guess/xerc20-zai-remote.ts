// import
import { ethers } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";
import implArtificat from "../../artifacts/contracts/periphery/connext/XERC20.sol/XERC20.json";
import { get } from "./_helpers";

// @ts-ignore
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const impl = new ethers.Contract(
  get("XERC20-impl", "arbitrum"),
  implArtificat.abi
);

const initData = impl.interface.encodeFunctionData("initialize", [
  "xZAI Stablecoin",
  "xUSDz",
  get("MAHATimelockController", "arbitrum"), // timelock
]);

const factoryAddress = get("Deployer", "arbitrum");
const constructorArgs: any[] = [
  impl.target, // implementation
  get("ProxyAdmin", "arbitrum"),
  initData, // init data
];

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
