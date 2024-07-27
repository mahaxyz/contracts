import hre, { ethers } from "hardhat";
import { buildBytecode } from "./create2";

async function main() {
  const constructorArgs: any[] = [
    86400 * 5,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC",
    ["0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"],
  ];

  const [wallet] = await hre.ethers.getSigners();

  const Deployer = await hre.ethers.getContractFactory("Deployer");

  const deployer = Deployer.attach(
    "0xc07c1980C87bfD5de0DC77f90Ce6508c1C0795C3"
  );

  const factory = await hre.ethers.getContractFactory("MAHATimelockController");

  const salt =
    "0xa518fb0108ec6d1659ec04d98aac4d5c06a0cebfe1e4ef55247ca5e262d5f50f";

  const bytecode = buildBytecode(
    ["uint256", "address", "address[]"],
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
