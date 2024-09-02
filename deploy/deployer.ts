import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  await deploy("Deployer", {
    from: deployer,
    contract: "Deployer",
    autoMine: true,
    log: true,
  });
}

main.tags = ["Deployer"];
export default main;
