import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { zeroPadValue } from "ethers";

task(`skip-oft-tx`, `Sets up the OFT with the right DVNs`)
  .addParam("targetnetwork", "The target network to send the OFT tokens to")
  .setAction(async ({ targetnetwork }, hre) => {
    const connections = Object.values(config);
    const connection = connections.find((c) => c.network === hre.network.name);
    if (!connection) throw new Error("cannot find connection");

    const target = connections.find((c) => c.network === targetnetwork);
    if (!target) throw new Error("cannot find connection");

    const [deployer] = await hre.ethers.getSigners();

    const oftD = await hre.deployments.get(connection.contract);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    await waitForTx(
      await endpoint.skip(
        oft.target, // address _oapp, //the Oapp address
        target.eid, // uint32 _srcEid, //source chain endpoint id
        zeroPadValue(deployer.address, 32), // bytes32 _sender, //the byte32 format of sender address
        1 // uint64 _nonce // the message nonce you wish to skip to
      )
    );
  });
