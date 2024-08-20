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
  .addParam("token", "either zai or maha")
  .addParam("targetnetwork", "The target network to send the OFT tokens to")
  .setAction(async ({ targetnetwork, token }, hre) => {
    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";
    const zaiD = await hre.deployments.get(contractNameToken);
    const erc20 = await hre.ethers.getContractAt(
      "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
      zaiD.address
    );
    const [deployer] = await hre.ethers.getSigners();

    const connections = Object.values(config);
    const source = connections.find((c) => c.network === hre.network.name);
    const target = connections.find((c) => c.network === targetnetwork);

    if (!source || !target) throw new Error("cannot find connection");

    const contractName = `${contractNameToken}${source.contract}`;
    const oftAdapterD = await hre.deployments.get(contractName);
    const oftAdapter = await hre.ethers.getContractAt(
      "LayerZeroCustomOFT",
      oftAdapterD.address
    );

    // Defining the amount of tokens to send and constructing the parameters for the send operation
    const tokensToSend = parseEther("0.1");

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

    if (
      source.network === "mainnet" &&
      (await erc20.allowance(deployer.address, oftAdapter.target)) == 0
    ) {
      // If the source network is mainnet, we need to approve the OFT adapter to spend the tokens
      await waitForTx(await erc20.approve(oftAdapter.target, MaxUint256));
    }

    console.log(await oftAdapter.quoteSend.populateTransaction(params, false));
    const [nativeFee] = await oftAdapter.quoteSend(params, false);

    const fee: MessagingFeeStruct = {
      nativeFee,
      lzTokenFee: 0n,
    };

    await waitForTx(
      await oftAdapter.send(params, fee, deployer.address, {
        value: nativeFee,
      })
    );
  });
