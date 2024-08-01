import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";

async function main() {
  const target = "0x998910da83fdC602452B61bFCd7A9f260363B897";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0"
  );

  const factory = await hre.ethers.getContractFactory("XERC20");
  const bytecode = buildBytecode([], [], factory.bytecode);

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id("" + 0), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("XERC20-impl", {
      address: target,
      args: [],
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: target,
    });
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
