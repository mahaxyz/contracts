import { TransactionReceipt, TransactionResponse } from "ethers";
import { HardhatRuntimeEnvironment } from "hardhat/types";

export function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function waitForTx(
  tx: TransactionResponse
): Promise<TransactionReceipt | null> {
  console.log("waiting for tx", tx.hash);
  return await tx.wait(1);
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
  name: string
) {
  const { deploy, save } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  const implementationD = await deploy(`${implementation}-Impl`, {
    from: deployer,
    contract: implementation,
    args: args,
    autoMine: true,
    log: true,
  });

  // todo encodeData

  const proxy = await deploy(`${name}-Proxy`, {
    from: deployer,
    contract: "MAHAProxy",
    args: [implementationD.address, proxyAdmin, "0x"],
    autoMine: true,
    log: true,
  });

  await save(name, {
    address: proxy.address,
    abi: implementationD.abi,
    args: args,
  });

  return proxyAdmin;
}
