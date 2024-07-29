import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const constructorArgs: any[] = ["0x690002da1f2d828d72aa89367623df7a432e85a9"];
  const salt =
    "0x2b51c962304bb35fa37a504feeb6a8ea4cf009c1b1a26a9aba4e9458ae0b69ba";
  const target = "0x6900064e7a3920c114e25b5fe4780f26520e3231";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const factory = await hre.ethers.getContractFactory("ProxyAdmin");

  const bytecode = buildBytecode(
    ["address"],
    constructorArgs,
    factory.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("ProxyAdmin", {
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
