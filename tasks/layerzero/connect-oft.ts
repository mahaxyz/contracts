import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { zeroPadValue } from "ethers";
import { get } from "../../scripts/guess/_helpers";

task(`connect-oft`, `Connects of all the OFT connections`).setAction(
  async (_, hre) => {
    const [deployer] = await hre.ethers.getSigners();

    const connections = Object.values(config);
    const connection = connections.find((c) => c.network === hre.network.name);
    console.log("current connection", connection);
    if (!connection) throw new Error("cannot find connection");

    const oftD = await hre.deployments.get(connection.contract);
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
      const remote = remoteConnections[index];
      const remoteD = get(remote.contract, remote.network);
      const remoteOft = zeroPadValue(remoteD, 32);
      console.log("\nnetwork", remote.network);
      console.log("remote peer  ", remoteOft);

      const peer = await oft.peers(remote.eid);
      console.log("received peer", peer);
      console.log("valid", peer.toLowerCase() == remoteOft.toLowerCase());

      if (peer.toLowerCase() != remoteOft.toLowerCase()) {
        // if we can set the peer, we will set it here
        if (owner == deployer.address) {
          console.log("setting peer for", remote.network);
          await waitForTx(await oft.setPeer(remote.eid, remoteOft));
        } else {
          const data = await oft.setPeer.populateTransaction(
            remote.eid,
            remoteOft
          );
          console.log("use to", data.to);
          console.log("use data", data.data);
        }
      }
    }
  }
);
