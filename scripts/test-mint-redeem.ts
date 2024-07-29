import { MaxUint256 } from "ethers";
import hre from "hardhat";
import { waitForTx } from "./utils";

async function main() {
  const { deployer } = await hre.getNamedAccounts();

  const symbol = "USDT";

  const usdcD = await hre.deployments.get(symbol);
  const collateral = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    usdcD.address
  );
  const zai = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0"
  );

  const psmD = await hre.deployments.get(`PegStabilityModule-${symbol}`);
  const psm = await hre.ethers.getContractAt(
    "PegStabilityModule",
    psmD.address
  );

  console.log("giving approvals");
  await waitForTx(await collateral.approve(psmD.address, MaxUint256));
  await waitForTx(await zai.approve(psmD.address, MaxUint256));

  console.log("testing psm mint", 100n * 10n ** 18n);
  await waitForTx(await psm.mint(deployer, 100n * 10n ** 18n));

  console.log("testing psm redeem");
  await waitForTx(await psm.redeem(deployer, 1n * 10n ** 18n));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
