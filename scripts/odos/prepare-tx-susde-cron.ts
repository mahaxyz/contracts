/* eslint-disable @typescript-eslint/naming-convention */
import { ethers } from "ethers";
import { Contract } from "ethers";
import { getGelatoCode } from "./helpers/path";
import { get } from "../guess/_helpers";

const main = async () => {
  const cron = get("sUSDeCollectorCron", "mainnet");
  const zai = get("ZAI", "mainnet");
  const susde = get("sUSDe", "mainnet") as `0x${string}`;

  const iface = new ethers.Interface([
    "function balanceOf(address who) public view returns (uint256 bal)",
    "function execute(bytes memory data) public payable",
  ]);

  const runner = new ethers.JsonRpcProvider("https://rpc.ankr.com/eth");
  const sUSDe = new Contract(susde, iface, runner);

  const bal = await sUSDe.balanceOf(cron);

  try {
    const ret = await getGelatoCode(1, zai, cron, [bal], [susde]);
    console.log("odos data", ret);

    console.log("tx data", {
      to: cron,
      data: iface.encodeFunctionData("execute", [ret.data]),
    });
  } catch (error: any) {
    console.log(error);
  }
};

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
