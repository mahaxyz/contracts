import assert from "assert";
import { ethers } from "ethers";
import fs from "fs";
import path from "path";
import { getCreate2Address } from "../create2/create2";
import proxyArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";

export function get(name: string, network: string): string {
  const data = fs.readFileSync(
    path.resolve(__dirname, `../../deployments/${network}/${name}.json`)
  );

  const res = JSON.parse(data.toString()).address as any as string;
  assert(res.length == 42, `invalid address for ${network}/${name}.json`);
  return res;
}

export function existsD(name: string, network: string): boolean {
  return fs.existsSync(
    path.resolve(__dirname, `../../deployments/${network}/${name}.json`)
  );
}

export const guessProxy = (
  implArtificat: any,
  implAddress: string,
  initFunction: string,
  initArgs: any[],
  network: string
) => {
  // @ts-ignore
  const constructorTypes = proxyArtifact.abi
    .find((v) => v.type === "constructor")
    ?.inputs.map((t) => t.type);

  const impl = new ethers.Contract(implAddress, implArtificat.abi);

  const initData = impl.interface.encodeFunctionData(initFunction, initArgs);

  const factoryAddress = get("Deployer", network);
  const constructorArgs: any[] = [
    impl.target, // implementation
    get("ProxyAdmin", network),
    initData, // init data
  ];

  console.log("constructor parameters", constructorTypes, constructorArgs);

  let i = 0;

  while (true) {
    const salt = ethers.id("" + i);
    // Calculate contract address
    const computedAddress = getCreate2Address({
      salt: salt,
      factoryAddress,
      contractBytecode: proxyArtifact.bytecode,
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

export const guess = (contractArtifact: any, args: any[], network: string) => {
  // @ts-ignore
  const constructorTypes = contractArtifact.abi
    .find((v) => v.type === "constructor")
    ?.inputs.map((t) => t.type);

  const factoryAddress = get("Deployer", network);

  console.log("constructor parameters", constructorTypes, args);

  let i = 0;

  while (true) {
    const salt = ethers.id("" + i);
    // Calculate contract address
    const computedAddress = getCreate2Address({
      salt: salt,
      factoryAddress,
      contractBytecode: contractArtifact.bytecode,
      constructorTypes: constructorTypes,
      constructorArgs: args,
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
