import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { zeroPadValue } from "ethers";

task(`setup-oft`, `Sets up the OFT with the right DVNs`).setAction(
  async (_, hre) => {
    const configTypeExec = 1; // As defined for CONFIG_TYPE_ULN
    const configTypeUln = 2; // As defined for CONFIG_TYPE_ULN

    const connections = Object.values(config);
    const connection = connections.find((c) => c.network === hre.network.name);
    if (!connection) throw new Error("cannot find connection");

    const remoteConnections = connections.filter(
      (c) => c.network !== hre.network.name
    );

    const ulnConfigStructType =
      "tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)";
    const configTypeExecutorStruct =
      "tuple(uint32 maxMessageSize, address executorAddress)";

    const encoder = new hre.ethers.AbiCoder();

    const oftD = await hre.deployments.get(connection.contract);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    // taken from https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-config
    for (let index = 0; index < remoteConnections.length; index++) {
      const remote = remoteConnections[index];
      console.log("setting up DVN routes for", remote.network);

      const ulnConfigData = {
        confirmations: connection.config.confirmations,
        requiredDVNCount: connection.config.requiredDVNs.length,
        optionalDVNCount: connection.config.optionalDVNs.length,
        optionalDVNThreshold: connection.config.optionalDVNThreshold,
        requiredDVNs: connection.config.requiredDVNs,
        optionalDVNs: connection.config.optionalDVNs,
      };

      const execConfigData = {
        maxMessageSize: 10000,
        executorAddress: connection.libraries.executor,
      };

      const ulnConfigEncoded = encoder.encode(
        [ulnConfigStructType],
        [ulnConfigData]
      );

      const execConfigEncoded = encoder.encode(
        [configTypeExecutorStruct],
        [execConfigData]
      );

      const setConfigParamUln = {
        eid: remote.eid, // Replace with your remote chain's endpoint ID (source or destination)
        configType: configTypeUln,
        config: ulnConfigEncoded,
      };

      const setConfigParamExecutor = {
        eid: remote.eid, // Replace with your remote chain's endpoint ID (source or destination)
        configType: configTypeExec,
        config: execConfigEncoded,
      };

      console.log("setConfigParamUln", setConfigParamUln);
      console.log("setConfigParamExecutor", setConfigParamExecutor);

      // setup the send config
      await waitForTx(
        await endpoint.setConfig(oft.target, connection.libraries.sendLib302, [
          setConfigParamUln,
          setConfigParamExecutor,
        ]),
        2
      );

      // setup the receive config
      await waitForTx(
        await endpoint.setConfig(
          oft.target,
          connection.libraries.receiveLib302,
          [setConfigParamUln]
        )
      );
    }
  }
);
