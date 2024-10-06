import { MaxUint256 } from "ethers";
import { ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, waitForTx } from "../../scripts/utils";
import assert from "assert";

async function main(hre: HardhatRuntimeEnvironment) {
  assert(hre.network.name === "base", "Wrong network");
  const { deployments } = hre;

  const args = [
    (await deployments.get("StakingLPRewards-sUSDZUSDC")).address,
    (await deployments.get("L2DepositCollateralL0")).address,
    (await deployments.get("AerodromeRouter")).address,
  ];

  const zapD = await deployContract(
    hre,
    "ZapAerodromePoolUSDC",
    args,
    "ZapAerodromePoolUSDC"
  );

  const zap = await ethers.getContractAt("ZapAerodromePoolUSDC", zapD.address);
  const usdc = await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    (
      await deployments.get("USDC")
    ).address
  );

  await waitForTx(await usdc.approve(zap.target, MaxUint256));
  await waitForTx(await zap.zapIntoLP(1e6, 0));
}

main.tags = ["ZapAerodromePoolUSDC"];
export default main;
