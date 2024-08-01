import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { get } from "../guess/_helpers";

async function main() {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory("XERC20");

  const implArgs = [
    "xZAI Stablecoin",
    "xUSDz",
    get("MAHATimelockController", "mainnet"), // timelock
  ];

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    get("XERC20-impl", "mainnet"),
    get("ProxyAdmin", "mainnet"),
    initData,
  ];

  const salt =
    "0x4ea02a3f883e1b7dcf6d14bad841870430b49b0b61b0c32083eb613c13fec79b";
  const target = "0x69000614b97a6a442dc72c07b948cd1e66f5bb83";

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    get("Deployer", "mainnet")
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), target)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save("XERC20-USDz", {
      address: target,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save("XERC20-USDz-Proxy", {
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
