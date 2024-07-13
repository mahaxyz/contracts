import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-ethers";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-dependency-compiler";
import "hardhat-abi-exporter";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-deploy";
import "solidity-coverage";
import "solidity-docgen";
import "hardhat-tracer";

import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  abiExporter: {
    path: "./abi",
    runOnCompile: true,
    clear: true,
    spacing: 2,
    format: "minimal",
  },
  docgen: {
    pages: "files",
    exclude: ["interfaces", "tests"],
  },
  gasReporter: {
    // @ts-ignore
    reportFormat: "terminal",
    outputFile: "coverage/gasReport.txt",
    noColors: true,
    forceTerminalOutput: true,
    forceTerminalOutputFormat: "terminal",
  },
  dependencyCompiler: {
    paths: [
      "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol",
    ],
  },
  typechain: {
    outDir: "types",
  },
  solidity: {
    version: "0.8.20",
  },
  networks: {
    // mainnet: {
    //   url: `https://rpc.ankr.com/eth`,
    //   accounts: [process.env.WALLET_PRIVATE_KEY || ""],
    //   saveDeployments: true,
    // },
  },
  namedAccounts: {
    deployer: 0,
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_KEY || "",
    },
  },
};

export default config;
