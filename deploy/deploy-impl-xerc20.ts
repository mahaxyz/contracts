import { network } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const psmImpl = await deploy("XERC20-impl", {
    from: deployer,
    contract: "XERC20",
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

main.tags = ["XERC20"];
export default main;
