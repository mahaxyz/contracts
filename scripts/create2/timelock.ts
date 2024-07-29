import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const constructorArgs: any[] = [
    60 * 60,
    "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC",
    ["0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC"],
  ];
  const salt =
    "0xd0e12b966b8f295eee7939e395339999e99db2caf2a53e482d881250122e5b39";
  const target = "0x690002da1f2d828d72aa89367623df7a432e85a9";

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

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("MAHATimelockController", {
      address: target,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: target,
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
