import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployContract } from "../../scripts/utils";

const main: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const szaiD = await deployments.get("SafetyPool-sZAI");
  const usdc = await deployments.get("USDC");
  const sUSDe = await deployments.get("sUSDe");

  const params = [
    "0xcf5540fffcdc3d510b18bfca6d2b9987b0772559", // address _odos,
    szaiD.address, // address _sZAI,
    sUSDe.address, // address _sUSDe,
    usdc.address, // address _usdc
  ];

  await deployContract(hre, "sUSDeCollectorCron", params, `sUSDeCollectorCron`);
};

export default main;
main.tags = ["sUSDeCollectorCron"];
