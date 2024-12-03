import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, deployProxy, waitForTx } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const plan = await deployContract(
    hre,
    "Erc20RecoverProxy",
    [],
    `Erc20RecoverProxy`
  );

  const proxy = await hre.ethers.getContractAt(
    "Erc20RecoverProxy",
    plan.address
  );

  console.log(
    await proxy.initialize.populateTransaction(
      "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      "0x77cd66d59ac48a0E7CE54fF16D9235a5fffF335E"
    )
  );
}

main.tags = ["Erc20RecoverProxy"];
export default main;
