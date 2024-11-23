import { TransactionReceipt, TransactionResponse } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import fs from "fs";
import path from "path";

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function waitForTx(
  tx: TransactionResponse,
  confirmations = 1
): Promise<TransactionReceipt | null> {
  console.log("waiting for tx", tx.hash);
  return await tx.wait(confirmations);
}

export async function verify(
  hre: HardhatRuntimeEnvironment,
  contractAddress: string,
  constructorArguments: any[] = []
) {
  try {
    console.log(`- Verifying ${contractAddress}`);

    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments: constructorArguments,
    });
  } catch (error) {
    console.log("Verify Error: ", contractAddress);
    console.log(error);
  }
}

export async function deployProxy(
  hre: HardhatRuntimeEnvironment,
  implementation: string,
  args: any[],
  proxyAdmin: string,
  name: string,
  sender?: string,
  skipInit = false
) {
  const { deploy, save } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  const implementationD = await deploy(`${implementation}-Impl`, {
    from: deployer,
    contract: implementation,
    skipIfAlreadyDeployed: true,
    // autoMine: true,
    // log: true,
  });

  const contract = await hre.ethers.getContractAt(
    implementation,
    implementationD.address
  );

  const argsInit = skipInit
    ? "0x"
    : contract.interface.encodeFunctionData("initialize", args);

  const proxy = await deploy(`${name}-Proxy`, {
    from: sender || deployer,
    contract: "MAHAProxy",
    skipIfAlreadyDeployed: true,
    args: [implementationD.address, proxyAdmin, argsInit],
    autoMine: true,
    log: true,
  });

  await save(name, {
    address: proxy.address,
    abi: implementationD.abi,
    args: args,
  });

  // if (hre.network.name !== "hardhat") {
  //   console.log("verifying contracts");
  //   await hre.run("verify:verify", {
  //     address: implementationD.address,
  //     constructorArguments: [],
  //   });
  //   await hre.run("verify:verify", {
  //     address: proxy.address,
  //     constructorArguments: [implementationD.address, proxyAdmin, argsInit],
  //   });
  // }

  return proxy;
}

export async function deployContract(
  hre: HardhatRuntimeEnvironment,
  implementation: string,
  args: any[],
  name: string
) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  const contract = await deploy(name, {
    from: deployer,
    contract: implementation,
    skipIfAlreadyDeployed: true,
    args: args,
    autoMine: true,
    log: true,
  });

  if (hre.network.name !== "hardhat") {
    console.log("verifying contracts");

    await hre.run("verify:verify", {
      address: contract.address,
      constructorArguments: args,
      // contract: implementation,
    });
  }

  return contract;
}

export const loadTasks = (taskFolders: string[]): void =>
  taskFolders.forEach((folder) => {
    const tasksPath = path.join(__dirname, "../tasks", folder);
    fs.readdirSync(tasksPath)
      .filter((pth) => pth.includes(".ts") || pth.includes(".js"))
      .forEach((task) => {
        require(`${tasksPath}/${task}`);
      });
  });
