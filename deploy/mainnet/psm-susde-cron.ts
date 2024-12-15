import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployContract } from "../../scripts/utils";

const main: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const szaiD = await deployments.get("SafetyPool-sZAI");
  const psm = await deployments.get("PegStabilityModule-sUSDe");
  const safe = await deployments.get("GnosisSafe");
  const oftAdapter = await deployments.get("ZaiStablecoinOFTAdapter");

  const params = [
    psm.address,
    szaiD.address,
    oftAdapter.address,
    safe.address, // address _treasury,
    safe.address, // address _mahaBuybacks,
    997, // uint256 _remoteSlippage,
    safe.address, // address _remoteAddr,
    30184, // uint32 _dstEID
  ];
  await deployContract(hre, "sUSDeCollectorCron", params, `sUSDeCollectorCron`);
};

export default main;
main.tags = ["sUSDeCollectorCron"];
