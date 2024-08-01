import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { get } from "../guess/_helpers";

async function main() {
  const constructorArgs: any[] = [get("MAHATimelockController", "arbitrum")];
  const salt =
    "0x86a0f351e764fdbad44e9da5c2796da3fbebddd97dba18ca9306b519fce81bfc";
  const target = "0x69000c978701fc4427d4baf749f10a5cec582863";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    get("Deployer", "arbitrum")
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
