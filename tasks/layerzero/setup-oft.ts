import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";

task(`setup-oft`, `Sets up the OFT with the right DVNs`).setAction(
  async (_, hre) => {
    const configTypeExec = 1; // As defined for CONFIG_TYPE_ULN
    const configTypeUln = 2; // As defined for CONFIG_TYPE_ULN

    const connections = Object.values(config);
    const c = connections.find((c) => c.network === hre.network.name);
    if (!c) throw new Error("cannot find connection");

    const remoteConnections = connections.filter(
      (c) => c.network !== hre.network.name
    );

    const ulnConfigStructType =
      "tuple(uint64 confirmations, uint8 requiredDVNCount, uint8 optionalDVNCount, uint8 optionalDVNThreshold, address[] requiredDVNs, address[] optionalDVNs)";
    const configTypeExecutorStruct =
      "tuple(uint32 maxMessageSize, address executorAddress)";

    const encoder = new hre.ethers.AbiCoder();

    const oftD = await hre.deployments.get(c.contract);
    const oft = await hre.ethers.getContractAt("OFT", oftD.address);
    const endpoint = await hre.ethers.getContractAt(
      "IL0EndpointV2",
      await oft.endpoint()
    );

    const execConfigData = {
      maxMessageSize: 10000,
      executorAddress: c.libraries.executor,
    };

    // taken from https://docs.layerzero.network/v2/developers/evm/protocol-gas-settings/default-config#setting-send-config
    for (let index = 0; index < remoteConnections.length; index++) {
      const r = remoteConnections[index];
      console.log("setting up DVN routes for", r.network);

      const ulnConfigDataSend = {
        confirmations: c.config.confirmations,
        requiredDVNCount: c.config.sendDVNs[r.network].requiredDVNs.length,
        optionalDVNCount: c.config.sendDVNs[r.network].optionalDVNs.length,
        optionalDVNThreshold: c.config.sendDVNs[r.network].optionalDVNThreshold,
        requiredDVNs: c.config.sendDVNs[r.network].requiredDVNs,
        optionalDVNs: c.config.sendDVNs[r.network].optionalDVNs,
      };

      const ulnConfigDataRecv = {
        confirmations: r.config.confirmations,
        requiredDVNCount: r.config.sendDVNs[c.network].requiredDVNs.length,
        optionalDVNCount: r.config.sendDVNs[c.network].optionalDVNs.length,
        optionalDVNThreshold: r.config.sendDVNs[c.network].optionalDVNThreshold,
        requiredDVNs: r.config.sendDVNs[c.network].requiredDVNs,
        optionalDVNs: r.config.sendDVNs[c.network].optionalDVNs,
      };

      const setConfigParamUlnSend = {
        eid: r.eid, // Replace with your remote chain's endpoint ID (source or destination)
        configType: configTypeUln,
        config: encoder.encode([ulnConfigStructType], [ulnConfigDataSend]),
      };

      const setConfigParamUlnRecv = {
        eid: r.eid, // Replace with your remote chain's endpoint ID (source or destination)
        configType: configTypeUln,
        config: encoder.encode([ulnConfigStructType], [ulnConfigDataRecv]),
      };

      const setConfigParamExecutor = {
        eid: r.eid, // Replace with your remote chain's endpoint ID (source or destination)
        configType: configTypeExec,
        config: encoder.encode([configTypeExecutorStruct], [execConfigData]),
      };

      console.log("setConfigParamUlnSend", setConfigParamUlnSend);
      console.log("setConfigParamExecutor", setConfigParamExecutor);

      // setup the send config
      await waitForTx(
        await endpoint.setConfig(oft.target, c.libraries.sendLib302, [
          setConfigParamUlnSend,
          setConfigParamExecutor,
        ]),
        2
      );

      // setup the receive config
      await waitForTx(
        await endpoint.setConfig(oft.target, c.libraries.receiveLib302, [
          setConfigParamUlnRecv,
        ])
      );
    }
  }
);
