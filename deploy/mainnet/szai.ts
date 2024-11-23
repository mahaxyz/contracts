import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ZeroAddress } from "ethers";
import { deployProxy } from "../../scripts/utils";

const main: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { getNamedAccounts, deployments } = hre;
  const { deployer } = await getNamedAccounts();

  const proxyAdminD = await deployments.get("ProxyAdmin");
  const zaiD = await deployments.get("ZaiStablecoin");
  const usdc = await deployments.get("USDC");
  const maha = await deployments.get("MAHA");

  const params = [
    zaiD.address, // address _stablecoin,
    deployer, // address _governance,
    usdc.address, // address _rewardToken1,
    maha.address, // address _rewardToken2,
    86400 * 7, // uint256 _rewardsDuration,
    ZeroAddress, // address _stakingBoost
  ];

  await deployProxy(
    hre,
    "SafetyPool",
    params,
    proxyAdminD.address,
    `SafetyPool-sZAI`,
    "0xbAd5D5073c18F43E986FDcF3c011646f3b481360" // wallet to deploy from
  );
};

export default main;
main.tags = ["SafetyPool-sZAI"];
