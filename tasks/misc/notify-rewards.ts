import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { MaxUint256, parseEther } from "ethers";

task(`notify-rewards`).setAction(async (_, hre) => {
  const deployments = await hre.deployments.all();
  const [deployer] = await hre.ethers.getSigners();

  const mahaD = await hre.deployments.get("MAHA");
  const maha = await hre.ethers.getContractAt("MAHA", mahaD.address);

  const rewardsD = await hre.deployments.get("StakingLPRewards-sUSDzUSDC");
  const rewards = await hre.ethers.getContractAt(
    "StakingLPRewards",
    rewardsD.address
  );

  const amount = parseEther("10");

  await waitForTx(await maha.approve(rewardsD.address, MaxUint256));
  await waitForTx(await rewards.notifyRewardAmount(maha.target, amount));
});
