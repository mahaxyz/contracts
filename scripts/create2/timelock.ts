import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { get } from "../guess/_helpers";

async function main() {
  const constructorArgs: any[] = [
    60 * 60,
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b",
    ["0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b"],
  ];
  const salt =
    "0xe0bcdd4e23c1a527f2e76f1cf91d3065c17f0259fd17bdb4525ab0b04d735d91";
  const target = "0x690005544ba364a53dcc9e8d81c9ce1e90018ab7";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    get("Deployer", "arbitrum")
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
