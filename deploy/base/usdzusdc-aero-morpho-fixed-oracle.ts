import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const proxyAdminD = await hre.deployments.get("ProxyAdmin");

  const price = 2n * 10n ** 24n;

  await deployProxy(
    hre,
    "MorphoFixedPriceOracleProxy",
    [price, 18],
    proxyAdminD.address,
    "AerodromeLPOracle-MorphoFixed-USDCUSDz"
  );
}

main.tags = ["LPOracle-Aero-Morpho-Fixed-sUSDZUSDC"];
export default main;
