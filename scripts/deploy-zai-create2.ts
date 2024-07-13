import hre, { ethers } from "hardhat";
import { buildBytecode } from "./create2";

async function main() {
  const constructorArgs: any[] = [
    "0x1a44076050125825900e736c501f859c50fE728c",
    "0xe5159e75ba5f1C9E386A3ad2FC7eA75c14629572",
  ];

  const [wallet] = await hre.ethers.getSigners();

  const Deployer = await hre.ethers.getContractFactory("Deployer");

  const deployer = Deployer.attach(
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  );

  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const salt =
    "0xcaf0534451ba5639c1d8c0dc6b1a98c11290ec6170f4bd4393463523460ecc59";

  const bytecode = buildBytecode(
    ["address", "address"],
    constructorArgs,
    factory.bytecode
  );

  const txPopulated = await deployer.deploy.populateTransaction(
    bytecode,
    ethers.id(salt)
  );
  const tx = await wallet.sendTransaction(txPopulated);

  const txR = await tx.wait(1);
  console.log(txR?.logs);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
