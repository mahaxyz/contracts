import { HardhatRuntimeEnvironment } from "hardhat/types";
import { network } from "hardhat";
async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const contract = await deploy("OmnichainStakingTokenImpl", {
    from: deployer,
    contract: "OmnichainStakingToken",
    autoMine: true,
    skipIfAlreadyDeployed: true,
    log: true,
  });

  console.log("OmnichainStakingTokenImpl deployed to:", contract.address);

   if (network.name !== "hardhat") {
      await hre.run("verify:verify", {
        address: contract.address,
      });
    }
}

main.tags = ["OmnichainStakingTokenImpl"];
export default main;