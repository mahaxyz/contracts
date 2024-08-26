import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract, deployProxy } from "../../scripts/utils";
import { config } from "../../tasks/layerzero/config";
import { get } from "../../scripts/guess/_helpers";
import { zeroPadValue } from "ethers";

async function main(hre: HardhatRuntimeEnvironment) {
  const l1Contract = get("L1BridgeCollateralL0", "mainnet");
  const zai = await hre.deployments.get("ZaiStablecoinOFT");
  const usdc = await hre.deployments.get("USDC");
  const stargate = await hre.deployments.get("StargateUSDCPool");
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();

  const { address: proxyAdmin } = await deployments.get("ProxyAdmin");

  const l1ContractPadded = zeroPadValue(l1Contract, 32);

  await deployProxy(
    hre,
    "L2DepositCollateralL0",
    [
      zai.address,
      usdc.address, // IERC20 _depositToken,
      stargate.address, // IStargate _stargate,
      l1ContractPadded, // bytes32 _bridgeTargetAddress,
      deployer, // address _governance,
      1e6, // uint256 _rate,
      1000000000000000, // uint256 _slippage - 0.1%
    ],
    proxyAdmin,
    "L2DepositCollateralL0"
  );
}

main.tags = ["L2DepositCollateralL0"];
export default main;
