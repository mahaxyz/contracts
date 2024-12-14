/* eslint-disable @typescript-eslint/naming-convention */
import {
  Web3Function,
  Web3FunctionContext,
} from "@gelatonetwork/web3-functions-sdk";
import { ethers } from "ethers";
import { Contract } from "ethers";
import { getGelatoCode } from "../../scripts/odos/helpers/path";

Web3Function.onRun(async (context: Web3FunctionContext) => {
  const { userArgs } = context;
  const { contractAddress, susdeAddress, zaiAddress } = userArgs as {
    contractAddress: string;
    susdeAddress: `0x${string}`;
    zaiAddress: `0x${string}`;
  };

  const iface = new ethers.Interface([
    "function balanceOf(address who) public view returns (uint256 bal)",
    "function execute(bytes memory data) public payable",
  ]);

  const runner = new ethers.JsonRpcProvider("https://rpc.ankr.com/eth");
  const sUSDe = new Contract(susdeAddress, iface, runner);

  const bal = await sUSDe.balanceOf(contractAddress);

  try {
    const ret = await getGelatoCode(
      1,
      zaiAddress,
      contractAddress,
      [bal],
      [susdeAddress]
    );

    return {
      canExec: true,
      callData: [
        {
          to: contractAddress,
          data: iface.encodeFunctionData("execute", [ret.data]),
        },
      ],
    };
  } catch (error: any) {
    const message = (error.message as string) || "";
    return {
      canExec: false,
      message,
    };
  }
});
