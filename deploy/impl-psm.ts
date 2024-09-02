import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const psmImpl = await deploy("PegStabilityModule-impl", {
    from: deployer,
    contract: "PegStabilityModule",
    args: [],
    autoMine: true,
    log: true,
  });

  if (network.name !== "hardhat") {
    await hre.run("verify:verify", {
      address: psmImpl.address,
    });
  }
}

main.tags = ["PegStabilityModule"];
export default main;
