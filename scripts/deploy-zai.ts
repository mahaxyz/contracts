import hre from "hardhat";

import { Deployer } from "../types";
import { buildBytecode } from "./create2";
import { ZeroAddress } from "ethers";

async function main() {
  const constructorArgs: any[] = [
    "0x1a44076050125825900e736c501f859c50fE728c",
    "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572",
  ];

  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const tx = await factory.deploy(...constructorArgs);
  console.log(tx.target);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
