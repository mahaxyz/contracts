import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../scripts/utils";
import { get } from "../scripts/guess/_helpers";
import { config as connextConfig } from "../tasks/connext/config";
import { network } from "hardhat";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { address: proxyAdmin } = await deployments.get("ProxyAdmin");

  const zaiD = await deployments.get("ZaiStablecoin");

  await deployProxy(
    hre,
    "L2DepositCollateral",
    [
      zaiD.address, // IERC20 _xZAI,
      connextConfig[network.name].usdc, // IERC20 _depositToken,
      connextConfig[network.name].zUsdc, // IERC20 _collateralToken,
      connextConfig[network.name].connext, // IConnext _connext,
      connextConfig[network.name].swapKeyNextUSDC, // bytes32 _swapKey,
      connextConfig.mainnet.domainId, // uint32 _bridgeDestinationDomain,
      get("L1BridgeCollateral", "mainnet"), // address _bridgeTargetAddress,
      deployer, // address _owner,
      1e6, // uint256 _rate,
      1e6, // uint256 _sweepBatchSize
    ],
    proxyAdmin,
    "L2DepositCollateral"
  );
}

main.tags = ["L2DepositCollateral"];
export default main;
