import { HardhatRuntimeEnvironment } from "hardhat/types";
import { deployProxy } from "../../scripts/utils";

async function main(hre: HardhatRuntimeEnvironment) {
  const LOCKER = "0x7DF7505aa7cfAb3AC1A8D1EC225f2fafe5f04c74";
  const MERKLE_ROOT =
    "0xe700a492541f4c7e5a5f4e47a71aff038d787285dc87ed00b06da83aefe0fadf";
  const { deployments } = hre;
  const MAHA = await deployments.get("MAHA");
  const proxyAdmin = await hre.deployments.get("ProxyAdmin");
  const MigratorProxy = await deployProxy(
    hre,
    "MigratorMaha",
    [MERKLE_ROOT, MAHA.address, LOCKER],
    proxyAdmin.address,
    "MigratorMaha"
  );

  console.log(`Migrator Maha Proxy Address ${MigratorProxy.address}`);
}

main.tags = ["MigratorMaha"];
export default main;
