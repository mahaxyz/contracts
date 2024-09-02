import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const contract = await deploy("StakingLPRewards-impl", {
    from: deployer,
    contract: "StakingLPRewards",
    args: [],
    autoMine: true,
    log: true,
  });

  if (network.name !== "hardhat") {
    await hre.run("verify:verify", {
      address: contract.address,
    });
  }
}

main.tags = ["StakingLPRewards"];
export default main;
