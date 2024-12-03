/* eslint-disable @typescript-eslint/naming-convention */
import { ethers } from "ethers";
import { Contract } from "ethers";
import { getGelatoCode } from "./helpers/path";
import { get } from "../guess/_helpers";

const main = async () => {
  const l1ContractD = get("L1BridgeCollateralL0", "mainnet");
  const tokenD = "0x73A15FeD60Bf67631dC6cd7Bc5B6e8da8190aCF5";
  const susde = get("sUSDe", "mainnet");

  const iface = new ethers.Interface([
    "function balanceOf(address who) public view returns (uint256 bal)",
    "function processWithOdos(address token, bytes memory data) public",
  ]);

  const runner = new ethers.JsonRpcProvider("https://rpc.ankr.com/eth");
  const token = new Contract(tokenD, iface, runner);

  const bal = await token.balanceOf(l1ContractD);

  try {
    const ret = await getGelatoCode(1, susde, l1ContractD, [bal], [tokenD]);
    console.log("odos data", ret);

    console.log("tx data", {
      to: l1ContractD,
      data: iface.encodeFunctionData("processWithOdos", [tokenD, ret.data]),
    });
  } catch (error: any) {
    console.log(error);
  }
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
