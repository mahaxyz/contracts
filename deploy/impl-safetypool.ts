import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const contract = await deploy("SafetyPool-impl", {
    from: deployer,
    contract: "SafetyPool",
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

main.tags = ["SafetyPool"];
export default main;
