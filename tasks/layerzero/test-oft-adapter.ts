import { task } from "hardhat/config";
import { waitForTx } from "../../scripts/utils";
import { config } from "./config";
import { Options } from "@layerzerolabs/lz-v2-utilities";

import { MaxUint256, parseEther, zeroPadValue } from "ethers";
import {
  MessagingFeeStruct,
  SendParamStruct,
} from "../../types/@layerzerolabs/lz-evm-oapp-v2/contracts/oft/OFT";

task(`test-oft-adapter`, `Tests the mainnet OFT adapter`)
  .addParam("targetnetwork", "The target network to send the OFT tokens to")
  .setAction(async ({ targetnetwork }, hre) => {
    const zaiD = await hre.deployments.get("ZaiStablecoin");
    const zai = await hre.ethers.getContractAt("ZaiStablecoin", zaiD.address);
    const [deployer] = await hre.ethers.getSigners();

    const connections = Object.values(config);
    const source = connections.find((c) => c.network === hre.network.name);
    const target = connections.find((c) => c.network === targetnetwork);

    if (!source || !target) throw new Error("cannot find connection");

    const oftAdapterD = await hre.deployments.get(source.contract);
    const oftAdapter = await hre.ethers.getContractAt(
      "LayerZeroCustomOFT",
      oftAdapterD.address
    );

    // Defining the amount of tokens to send and constructing the parameters for the send operation
    const tokensToSend = parseEther("1");

    // Defining extra message execution options for the send operation
    const options = Options.newOptions()
      .addExecutorLzReceiveOption(200000, 0)
      .toHex()
      .toString();

    const params: SendParamStruct = {
      dstEid: target.eid,
      to: zeroPadValue(deployer.address, 32),
      amountLD: tokensToSend,
      minAmountLD: tokensToSend,
      extraOptions: options,
      composeMsg: "0x",
      oftCmd: "0x",
    };

    console.log(
      params,
      await oftAdapter.quoteSend.populateTransaction(params, false)
    );
    const [nativeFee] = await oftAdapter.quoteSend(params, false);

    const fee: MessagingFeeStruct = {
      nativeFee,
      lzTokenFee: 0n,
    };

    // await waitForTx(await zai.approve(oftAdapter.target, MaxUint256));
    await waitForTx(
      await oftAdapter.send(params, fee, deployer.address, {
        value: nativeFee,
      })
    );
  });
