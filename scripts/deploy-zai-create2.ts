import hre, { ethers } from "hardhat";
import { buildBytecode } from "./create2";

async function main() {
  const constructorArgs: any[] = [];

  const [wallet] = await hre.ethers.getSigners();

  const Deployer = await hre.ethers.getContractFactory("Deployer");

  const deployer = Deployer.attach(
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  );

  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const salt =
    "0xbfbe43cf56a21dc5a9a6273a76377c16bbcd057f6bbf23d6a4619baa8d1a8004";

  const bytecode = buildBytecode([], constructorArgs, factory.bytecode);

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
