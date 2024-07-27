import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const timelockD = await deployments.get("MAHATimelockController");

  const admin = await deploy("ProxyAdmin", {
    from: deployer,
    contract: "ProxyAdmin",
    args: [timelockD.address],
    autoMine: true,
    log: true,
  });

  if (network.name !== "hardhat") {
    await hre.run("verify:verify", {
      address: admin.address,
      constructorArguments: [timelockD.address],
    });
  }
}

main.tags = ["ProxyAdmin"];
export default main;
