import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const constructorArgs: any[] = [
    86400 * 5,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC",
    ["0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"],
  ];
  const salt =
    "0x69d6d41e98a79d76ddcc4edd70bfc8205509588f3b307cf950fdf68e6a18e006";
  const address = "0x69000d5a9f4ca229227b90f61285f5866d139f11";

  const [wallet] = await hre.ethers.getSigners();
  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const factory = await hre.ethers.getContractFactory("MAHATimelockController");

  const bytecode = buildBytecode(
    ["uint256", "address", "address[]"],
    constructorArgs,
    factory.bytecode
  );

  const txPopulated = await deployer.deploy.populateTransaction(
    bytecode,
    ethers.id(salt)
  );

  const txR = await waitForTx(await wallet.sendTransaction(txPopulated));
  console.log(txR?.logs);

  if (network.name !== "hardhat") {
    await hre.deployments.save("MAHATimelockController", {
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
