import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("ZAIStablecoin", {
    from: deployer,
    contract: "ZAIStablecoin",
    autoMine: true,
    log: true,
  });
}

main.tags = ["ZAIStablecoin"];
export default main;
