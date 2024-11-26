import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const LOCKER = "0x7DF7505aa7cfAb3AC1A8D1EC225f2fafe5f04c74";
  const MERKLE_ROOT = "0x9547986592f11cd509fb211d694eb556636e7ec75a5d879d404c98ecf6d211fb";
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const MAHA = await deployments.get("MAHA");
  const MigratorProxy = await deployProxy(
    hre,
    "MigratorMaha",
    [MERKLE_ROOT, MAHA.address, LOCKER],
    deployer,
    "MigratorMaha"
  );

  console.log(`Migrator Maha Proxy Address ${MigratorProxy.address}`);
}

main.tags = ["MigratorMaha"];
export default main;
