/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat transfer-ofts-ownership --network arbitrum --token maha
  npx hardhat transfer-ofts-ownership --network base --token maha
  npx hardhat transfer-ofts-ownership --network bsc --token maha
  npx hardhat transfer-ofts-ownership --network xlayer --token maha
  npx hardhat transfer-ofts-ownership --network linea --token maha
  npx hardhat transfer-ofts-ownership --network mainnet --token maha
  npx hardhat transfer-ofts-ownership --network optimism --token maha
  npx hardhat transfer-ofts-ownership --network sonic --token maha
  npx hardhat transfer-ofts-ownership --network unichain --token maha
 */
import _ from "underscore";
import { config } from "./config";
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";

task(`transfer-ofts-ownership`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    // await hre.run("setup-oft", { token });

    const [deployer] = await hre.ethers.getSigners();
    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;

    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt(
      "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol:OFT",
      oftD.address
    );
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    const timelockD = await hre.deployments.get("MAHATimelockController");
    const safeD = await hre.deployments.get("GnosisSafe");

    const owner = await oft.owner();
    console.log("\nworking on network", hre.network.name);
    console.log("current delegate", await endpoint.delegates(oftD.address));
    console.log("current owner", owner);

    if (owner.toLowerCase() == deployer.address.toLowerCase()) {
      console.log("\ntransferring ownership to timelock and safe");
      await waitForTx(await oft.setDelegate(safeD.address));
      await waitForTx(await oft.transferOwnership(timelockD.address));
    }

    console.log("\nnew delegate", await endpoint.delegates(oftD.address));
    console.log("new owner", await oft.owner());
  });
