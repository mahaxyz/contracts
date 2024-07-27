import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";

async function main() {
  const constructorArgs: any[] = ["0x69000d5a9f4ca229227b90f61285f5866d139f11"];
  const salt =
    "0x201f9ccf664d63a838c47d6d856dd2fa22f1a107bd0e4c83debe9092b05f7439";
  const address = "0x69000f2f879ee598ddf16c6c33cfc4f2d983b6bd";

  const [wallet] = await hre.ethers.getSigners();
  const deployerD = await hre.deployments.get("Deployer");
  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    deployerD.address
  );

  const factory = await hre.ethers.getContractFactory("ProxyAdmin");

  const bytecode = buildBytecode(
    ["address"],
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

  if (network.name !== "hardhat") {
    await hre.deployments.save("ProxyAdmin", {
      address: address,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: address,
      constructorArguments: constructorArgs,
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
