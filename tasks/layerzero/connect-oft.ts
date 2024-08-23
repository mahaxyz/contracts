/**

  Script to connect OFTs for the Zai and Maha tokens on the various networks.

  npx hardhat connect-oft --token zai --network arbitrum
  npx hardhat connect-oft --token zai --network base
  npx hardhat connect-oft --token zai --network blast
  npx hardhat connect-oft --token zai --network bsc
  npx hardhat connect-oft --token zai --network linea
  npx hardhat connect-oft --token zai --network optimism
  npx hardhat connect-oft --token zai --network xlayer
  npx hardhat connect-oft --token zai --network mainnet
  npx hardhat connect-oft --token zai --network scroll

 */
import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { zeroPadValue } from "ethers";
import { existsD, get } from "../../scripts/guess/_helpers";

task(`connect-oft`, `Connects of all the OFT connections`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    const c = config[hre.network.name];
    if (!c) throw new Error("cannot find connection");

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const contractName = `${contractNameToken}${c.contract}`;

    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    const remoteConnections = Object.keys(config).filter(
      (c) => c !== hre.network.name
    );
    const owner = await oft.owner();
    const delegate = await endpoint.delegates(oft.target);

    console.log("owner", owner);
    console.log("delegate", delegate);
    console.log("valid", delegate.toLowerCase() == owner.toLowerCase());

    for (let index = 0; index < remoteConnections.length; index++) {
      const remoteNetwork = remoteConnections[index];
      const r = config[remoteNetwork];
      const remoteContractName = `${contractNameToken}${r.contract}`;

      if (!existsD(remoteContractName, remoteNetwork)) {
        console.log("no contract found for", remoteNetwork);
        continue;
      }

      const remoteD = get(remoteContractName, remoteNetwork);
      const remoteOft = zeroPadValue(remoteD, 32);
      console.log("\nnetwork", remoteNetwork, "for", hre.network.name);
      console.log("remote peer  ", remoteOft);

      const peer = await oft.peers(r.eid);
      console.log("received peer", peer);
      console.log("valid", peer.toLowerCase() == remoteOft.toLowerCase());

      if (peer.toLowerCase() != remoteOft.toLowerCase()) {
        // if we can set the peer, we will set it here
        if (owner == deployer.address) {
          console.log("setting peer for", remoteNetwork);
          await waitForTx(
            await oft.setPeer(r.eid, remoteOft, {
              gasPrice: 1000000000,
            })
          );
        } else {
          const data = await oft.setPeer.populateTransaction(r.eid, remoteOft);
          console.log("use to", data.to);
          console.log("use data", data.data);
        }
      }
    }
  });
