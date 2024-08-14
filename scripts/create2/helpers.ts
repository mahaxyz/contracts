import hre, { ethers, network } from "hardhat";
import { buildBytecode } from "./create2";
import { waitForTx } from "../utils";
import { get } from "../guess/_helpers";

export const executeCreate2Proxy = async (
  name: string,
  proxyName: string,
  implContract: string,
  implArgs: string[],
  implAddress: string,
  _network: string,
  salt: string,
  expectedAddress: string
) => {
  const factory = await hre.ethers.getContractFactory("MAHAProxy");
  const impl = await hre.ethers.getContractFactory(implContract);

  const initData = impl.interface.encodeFunctionData("initialize", implArgs);

  const constructorArgs: any[] = [
    implAddress,
    get("ProxyAdmin", _network),
    initData,
  ];

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    get("Deployer", _network)
  );

  const bytecode = buildBytecode(
    ["address", "address", "bytes"],
    constructorArgs,
    factory.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), expectedAddress)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save(name, {
      address: expectedAddress,
      args: implArgs,
      abi: impl.interface.format(true),
    });

    await hre.deployments.save(proxyName, {
      address: expectedAddress,
      args: constructorArgs,
      abi: factory.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: expectedAddress,
      constructorArguments: constructorArgs,
    });
  }
};

export const executeCreate2 = async (
  name: string,
  implContract: string,
  constructorArgs: string[],
  _network: string,
  salt: string,
  expectedAddress: string
) => {
  const impl = await hre.ethers.getContractFactory(implContract);

  const constructorTypes =
    impl.interface.fragments
      .find((v) => v.type === "constructor")
      ?.inputs.map((t) => t.type) || [];

  const deployer = await hre.ethers.getContractAt(
    "Deployer",
    get("Deployer", _network)
  );

  const bytecode = buildBytecode(
    constructorTypes,
    constructorArgs,
    impl.bytecode
  );

  await waitForTx(
    await deployer.deployWithAssert(bytecode, ethers.id(salt), expectedAddress)
  );

  if (network.name !== "hardhat") {
    await hre.deployments.save(name, {
      address: expectedAddress,
      args: constructorArgs,
      abi: impl.interface.format(true),
    });

    await hre.run("verify:verify", {
      address: expectedAddress,
      constructorArguments: constructorArgs,
    });
  }
};
