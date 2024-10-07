import { MaxUint256, ZeroAddress } from "ethers";
import { ethers, network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { waitForTx } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const args = [
    (await deployments.get("SafetyPool-USDz")).address,
    (await deployments.get("ZaiStablecoin")).address,
  ];

  const zapD = await deploy("ZapSafetyPool", {
    from: deployer,
    contract: "ZapSafetyPool",
    args: args,
    autoMine: true,
    log: true,
  });

  const zap = await ethers.getContractAt("ZapSafetyPool", zapD.address);
  const usdc = await ethers.getContractAt(
    "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
    "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
  );

  await waitForTx(await usdc.approve(zap.target, MaxUint256));
  await waitForTx(
    await zap.zapIntoSafetyPool(
      (
        await deployments.get("PegStabilityModule-USDC")
      ).address,
      10e6
    )
  );

  if (network.name !== "hardhat") {
    console.log("verifying contracts");
    await hre.run("verify:verify", {
      address: zapD.address,
      constructorArguments: args,
    });
  }
}

main.tags = ["ZapSafetyPool"];
export default main;
