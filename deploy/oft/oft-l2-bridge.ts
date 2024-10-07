import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy, waitForTx } from "../../scripts/utils";
import { get } from "../../scripts/guess/_helpers";
import { ZeroAddress, zeroPadValue } from "ethers";

async function main(hre: HardhatRuntimeEnvironment) {
  const l1Contract = get("L1BridgeCollateralL0", "mainnet");
  const zaiD = await hre.deployments.get("ZaiStablecoinOFT");
  const usdc = await hre.deployments.get("USDC");
  const stargate = await hre.deployments.getOrNull("StargateUSDCPool");
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const { address: proxyAdmin } = await deployments.get("ProxyAdmin");

  const zai = await hre.ethers.getContractAt(
    "ZaiOFTWithRestaking",
    zaiD.address
  );
  const l1ContractPadded = zeroPadValue(l1Contract, 32);

  const restaker = await deployProxy(
    hre,
    "L2DepositCollateralL0",
    [
      zaiD.address,
      usdc.address, // IERC20 _depositToken,
      stargate ? stargate.address : ZeroAddress, // IStargate _stargate,
      l1ContractPadded, // bytes32 _bridgeTargetAddress,
      deployer, // address _governance,
      1e6, // uint256 _rate,
      1000000000000000, // uint256 _slippage - 0.1%
    ],
    proxyAdmin,
    "L2DepositCollateralL0"
  );

  await waitForTx(await zai.setRestaker(restaker.address));
}

main.tags = ["L2DepositCollateralL0"];
export default main;
