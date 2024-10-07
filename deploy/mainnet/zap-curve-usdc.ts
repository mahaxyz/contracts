import { MaxUint256 } from "ethers";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, waitForTx } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;

  const args = [
    (await deployments.get("StakingLPRewards-ssUSDzUSDz")).address,
    (await deployments.get("PegStabilityModule-USDC")).address,
  ];

  const zapD = await deployContract(
    hre,
    "ZapCurvePoolUSDC",
    args,
    "ZapCurvePoolUSDC"
  );

  const zap = await ethers.getContractAt("ZapCurvePoolUSDC", zapD.address);
  const usdc = await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
  );

  await waitForTx(await usdc.approve(zap.target, MaxUint256));
  await waitForTx(await zap.zapIntoLP(10e6, 0));
}

main.tags = ["ZapCurvePoolUSDC"];
export default main;
