/**

  Script to connect OFTs for the Zai and Maha tokens on the various networks.

  npx hardhat connect-oft --token zai --network arbitrum
  npx hardhat connect-oft --token zai --network base
  npx hardhat connect-oft --token zai --network blast
  npx hardhat connect-oft --token zai --network bsc
  npx hardhat connect-oft --token zai --network linea
  npx hardhat connect-oft --token zai --network optimism
  npx hardhat connect-oft --token zai --network xlayer
  npx hardhat connect-oft --token zai --network mainnet
  npx hardhat connect-oft --token zai --network scroll

 */
import { task } from "hardhat/config";
import { config } from "./config";
import { get } from "../../scripts/guess/_helpers";

task(`print-ofts`, `Prints all the OFTs`)
  .addParam("token", "either zai or maha")
  .setAction(async ({ token }) => {
    const networks = Object.keys(config);
    const contractNameToken = token === "zai" ? "ZaiStablecoin" : "MAHA";

    for (let index = 0; index < networks.length; index++) {
      const network = networks[index];
      const addr = get(contractNameToken, network);
      console.log(network, addr);
    }
  });
