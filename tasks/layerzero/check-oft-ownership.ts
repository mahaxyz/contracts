/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat check-oft-ownership --token zai --network arbitrum
  npx hardhat check-oft-ownership --token zai --network base
  npx hardhat check-oft-ownership --token zai --network blast
  npx hardhat check-oft-ownership --token zai --network bsc
  npx hardhat check-oft-ownership --token zai --network linea
  npx hardhat check-oft-ownership --token zai --network optimism
  npx hardhat check-oft-ownership --token zai --network xlayer
  npx hardhat check-oft-ownership --token zai --network mainnet
  npx hardhat check-oft-ownership --token zai --network scroll
 */
import _ from "underscore";
import { config } from "./config";
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { existsD } from "../../scripts/helpers";

task(`check-oft-ownership`, `Checks the OFT's ownership`)
  .addParam("token", "either zai or maha")
  .addOptionalParam("execute", "execute the ownership transfer to safe")
  .setAction(async ({ execute, token }, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection: " + hre.network.name);

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;
    const [deployer] = await hre.ethers.getSigners();

    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt(
      "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol:OFT",
      oftD.address
    );
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    console.log("\nchecking for", hre.network.name);
    console.log("deployer", deployer.address);
    console.log("current owner", await oft.owner());
    console.log("current delegate", await endpoint.delegates(oft.target));

    if (!(await existsD("GnosisSafe", hre.network.name))) return;

    const safe = await hre.deployments.get(`GnosisSafe`);
    console.log("safe", safe.address);
    if (execute == "1" && (await oft.owner()) !== safe.address) {
      const isContract = await hre.network.provider.request({
        method: "eth_getCode",
        params: [safe.address, "latest"],
      });

      if (isContract !== "0x") {
        console.log("executing changes");
        await waitForTx(await oft.setDelegate(safe.address));
        await waitForTx(await oft.transferOwnership(safe.address));
      } else {
        console.log("Address is not a safe");
      }
    }
    console.log("done");
  });
