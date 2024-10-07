/**

  Script to send a test OFT to a target network

  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network arbitrum
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network base
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network blast
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network bsc
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network linea
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network optimism
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network xlayer
  npx hardhat test-oft-adapter --amt 1 --targetnetwork mainnet --token zai  --network scroll

 */
import { task } from "hardhat/config";
import { config } from "./config";

task(
  `test-oft-adapter-multi`,
  `Tests the mainnet OFT adapter across mulitple chains`
)
  .addParam("token", "either zai or maha")
  .addParam("amt", "the amount of tokens")
  .setAction(async ({ token, amt }, hre) => {
    const networks = Object.keys(config).filter((n) => n !== hre.network.name);
    for (let index = 0; index < networks.length; index++) {
      const network = networks[index];

      try {
        await hre.run("test-oft-adapter", {
          token,
          amt,
          targetnetwork: network,
        });
      } catch (e) {
        console.log("error", e);
        console.log("send failed for network", network);
      }
    }
  });
