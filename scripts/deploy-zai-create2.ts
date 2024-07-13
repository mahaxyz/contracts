import hre from "hardhat";

import { Deployer } from "../types";
import { buildBytecode } from "./create2";
import { ZeroAddress } from "ethers";

export const constructorArgs: any[] = [
  "0x1a44076050125825900e736c501f859c50fE728c",
  "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572",
];

async function main() {
  const [wallet] = await hre.ethers.getSigners();

  const deployer = (await hre.ethers.getContractAt(
    "Deployer",
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  )) as any as Deployer;

  const ZaiFactory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const salt =
    "0xbfe35a3d9c7dc29f27ac2ba553f5cbae6f24ee324d2893f052bb71a940bd40d6";

  const bytecode = buildBytecode(
    ["address", "address"],
    constructorArgs,
    ZaiFactory.bytecode
  );

  console.log("bytecode", bytecode.toString());
  const deployed = await deployer.connect(wallet).deploy(bytecode, salt);

  const tx = await deployed.wait(1);
  console.log(tx?.logs);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
