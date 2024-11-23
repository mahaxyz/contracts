import { MaxUint256 } from "ethers";
import hre from "hardhat";
import { waitForTx } from "./utils";

async function main() {
  const { deployer } = await hre.getNamedAccounts();

  const zaiD = await hre.deployments.get("ZAI");
  const szaiD = await hre.deployments.get("sZAI");

  const zai = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    zaiD.address
  );

  const szai = await hre.ethers.getContractAt("SafetyPool", szaiD.address);

  console.log("giving approvals");
  await waitForTx(await zai.approve(szaiD.address, MaxUint256));
  await waitForTx(await szai.mint(10n * 10n ** 18n, deployer));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
