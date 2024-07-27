import { MaxUint256 } from "ethers";
import hre from "hardhat";

async function main() {
  const { deployer } = await hre.getNamedAccounts();

  const symbol = "USDC";

  const usdcD = await hre.deployments.get(symbol);
  const collateral = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    usdcD.address
  );
  const zai = await hre.ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    "0x6900057428C99Fb373397D657Beb40D92D8aC97f"
  );

  const psmD = await hre.deployments.get(`PegStabilityModule-${symbol}`);
  const psm = await hre.ethers.getContractAt(
    "PegStabilityModule",
    psmD.address
  );

  // console.log("giving approvals");
  await collateral.approve(psmD.address, MaxUint256);
  const tx1 = await zai.approve(psmD.address, MaxUint256);
  await tx1.wait(1);

  console.log("testing psm mint", 10n * 10n ** 18n);
  const tx2 = await psm.mint(deployer, 10n * 10n ** 18n);
  await tx2.wait(1);

  console.log("testing psm redeem");
  await psm.redeem(deployer, 1n * 10n ** 18n);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
