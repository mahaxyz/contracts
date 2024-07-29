import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const constructorArgs: any[] = ["0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b"];
  const salt =
    "0x7e5eb0064d6dcdd0dbd023d9b02d765c721ac4f0d8b25e904ca7b35dbf5e151d";
  const target = "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0";
  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const factory = await hre.ethers.getContractFactory("ZaiStablecoin");

  const bytecode = buildBytecode(
    ["address"],
    constructorArgs,
    factory.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("ZaiStablecoin", {
      address: target,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: target,
      contract: "contracts/core/ZaiStablecoin.sol:ZaiStablecoin",
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
