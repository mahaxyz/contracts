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

  const destinationL2 = "0x12eB0D746E6b3172d467a606ac071D86b6747E7A";
  const safeL1 = "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC";

  const params = [
    ddHubD.address, // address _hub,
    zaiD.address, // address _zai,
    zeroPadValue(destinationL2, 32), // bytes32 _destinationL2,
    adapterD.address, // address _oftAdapter,
    config.xlayer.eid, // uint32 _dstEid
  ];

  await deployProxy(
    hre,
    "DDLayerZeroHub",
    params,
    proxyAdminD.address,
    `DDLayerZeroHub-OKX-LZ`
  );

  await deployContract(
    hre,
    "DDOperatorPlan",
    [
      3600, // uint48 _initialDelay,
      deployer.address, // address _governance
    ],
    `DDOperatorPlan-OKX-LZ`
  );
}

main.tags = ["DeployDDHub-OKX-LZ"];
export default main;
