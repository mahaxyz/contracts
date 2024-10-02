/**
  Script to setup OFTs for the token on the various networks.

  npx hardhat check-oft-ownership --network arbitrum --execute 0 --token zai
  npx hardhat check-oft-ownership --network base --execute 0 --token zai
  npx hardhat check-oft-ownership --network blast --execute 0 --token zai
  npx hardhat check-oft-ownership --network bsc --execute 0 --token zai
  npx hardhat check-oft-ownership --network xlayer --execute 0 --token zai
  npx hardhat check-oft-ownership --network linea --execute 0 --token zai
  npx hardhat check-oft-ownership --network zircuit --execute 0 --token zai
  npx hardhat check-oft-ownership --network manta --execute 0 --token zai
  npx hardhat check-oft-ownership --network mainnet --execute 0 --token zai
 */
import _ from "underscore";
import { config } from "./config";
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";

task(`check-oft-ownership`, `Checks the OFT's ownership`)
  .addParam("token", "either zai or maha")
  .addOptionalParam("execute", "execute the ownership transfer to safe")
  .setAction(async ({ execute, token }, hre) => {
    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;

    const safe = await hre.deployments.get(`GnosisSafe`);
    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt(
      "@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT.sol:OFT",
      oftD.address
    );
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    console.log("checking for", hre.network.name);
    console.log("safe", safe.address);
    console.log("current owner", await oft.owner());
    console.log("current delegate", await endpoint.delegates(oft.target));

    if (execute && (await oft.owner()) !== safe.address) {
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
    console.log("done\n");
  });
