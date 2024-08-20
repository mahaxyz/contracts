import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { zeroPadValue } from "ethers";
import { existsD, get } from "../../scripts/guess/_helpers";

task(`connect-oft`, `Connects of all the OFT connections`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    const connections = Object.values(config);
    const c = connections.find((c) => c.network === hre.network.name);
    console.log("current connection", c);
    if (!c) throw new Error("cannot find connection");

    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "Maha";
    const contractName = `${contractNameToken}${c.contract}`;

    const oftD = await hre.deployments.get(contractName);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    const remoteConnections = connections.filter(
      (c) => c.network !== hre.network.name
    );
    const owner = await oft.owner();
    const delegate = await endpoint.delegates(oft.target);

    console.log("owner", owner);
    console.log("delegate", delegate);
    console.log("valid", delegate.toLowerCase() == owner.toLowerCase());

    for (let index = 0; index < remoteConnections.length; index++) {
      const r = remoteConnections[index];
      const remoteContractName = `${contractNameToken}${r.contract}`;

      if (!existsD(remoteContractName, r.network)) continue;

      const remoteD = get(remoteContractName, r.network);
      const remoteOft = zeroPadValue(remoteD, 32);
      console.log("\nnetwork", r.network);
      console.log("remote peer  ", remoteOft);

      const peer = await oft.peers(r.eid);
      console.log("received peer", peer);
      console.log("valid", peer.toLowerCase() == remoteOft.toLowerCase());

      if (peer.toLowerCase() != remoteOft.toLowerCase()) {
        // if we can set the peer, we will set it here
        if (owner == deployer.address) {
          console.log("setting peer for", r.network);
          await waitForTx(await oft.setPeer(r.eid, remoteOft));
        } else {
          const data = await oft.setPeer.populateTransaction(r.eid, remoteOft);
          console.log("use to", data.to);
          console.log("use data", data.data);
        }
      }
    }
  });
