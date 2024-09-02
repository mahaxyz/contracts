import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, deployProxy } from "../../scripts/utils";
import assert from "assert";
import { config } from "../../tasks/layerzero/config";
import { zeroPadValue } from "ethers";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments } = hre;
  assert(hre.network.name === "mainnet", "Wrong network");

  const [deployer] = await hre.ethers.getSigners();
  const proxyAdminD = await deployments.get("ProxyAdmin");
  const ddHubD = await deployments.get("DDHub");
  const zaiD = await deployments.get("ZaiStablecoin");
  const adapterD = await deployments.get("ZaiStablecoinOFTAdapter");

  const destinationL2 = "0x7427E82f5abCbcA2a45cAfE6e65cBC1FADf9ad9D";
  const safeL1 = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const params = [
    ddHubD.address, // address _hub,
    zaiD.address, // address _zai,
    zeroPadValue(destinationL2, 32), // bytes32 _destinationL2,
    adapterD.address, // address _oftAdapter,
    config.base.eid, // uint32 _dstEid
  ];

  await deployProxy(
    hre,
    "DDLayerZeroHub",
    params,
    proxyAdminD.address,
    `DDLayerZeroHub-Base-LZ`
  );

  await deployContract(
    hre,
    "DDOperatorPlan",
    [
      3600, // uint48 _initialDelay,
      deployer.address, // address _governance
      10n ** 24n, // uint256 _targetAssets, - 1mn USDz
    ],
    `DDOperatorPlan-Base-LZ`
  );
}

main.tags = ["DeployDDHub-Base-LZ"];
export default main;
