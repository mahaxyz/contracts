import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployContract } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const oracleA = "0xeAA79aaC2decf71F07c3208Df05B198d09c9F971";
  const oracleB = "0xeAA79aaC2decf71F07c3208Df05B198d09c9F971";
  const pool = "0x72d509aff75753aaad6a10d3eb98f2dbc58c480d";

  await deployContract(
    hre,
    "AerodromeLPOracle",
    [oracleA, oracleB, pool],
    "AerodromeLPOracle-USDCUSDz"
  );
}

main.tags = ["LPOracle-Aero-sUSDZUSDC"];
export default main;
