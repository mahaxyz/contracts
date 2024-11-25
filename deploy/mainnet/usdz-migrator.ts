import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { deployContract } from "../../scripts/utils";

const main: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  const zaiD = await deployments.get("ZaiStablecoin");

  const params = [
    "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // old USDz address
    zaiD.address, // address _stablecoin,
  ];

  await deployContract(hre, "UsdzMigrator", params, `UsdzMigrator`);
};

export default main;
main.tags = ["UsdzMigrator"];
