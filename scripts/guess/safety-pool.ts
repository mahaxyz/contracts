// import
import { ethers, ZeroAddress } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";
import implArtificat from "../../artifacts/contracts/core/safety-pool/SafetyPool.sol/SafetyPool.json";

// @ts-ignore
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const impl = new ethers.Contract(
  "0xb6761274addfCF738344Ac4C6566AD5c0255Aaa0",
  implArtificat.abi
);

const initData = impl.interface.encodeFunctionData("initialize", [
  "Staked ZAI Stablecoin", // string memory _name,
  "sUSDz", // string memory _symbol,
  "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _stablecoin,
  86400 * 10, // uint256 _withdrawalDelay,
  "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _governance,
  "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _rewardToken1,
  "0x745407c86df8db893011912d3ab28e68b62e49b0", // address _rewardToken2,
  86400 * 7, // uint256 _rewardsDuration,
  ZeroAddress, // address _stakingBoost
]);

const factoryAddress = "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0";
const constructorArgs: any[] = [
  impl.target, // implementation
  "0x6900064e7a3920c114e25b5fe4780f26520e3231", // proxyadmin
  initData, // init data
];

console.log("constructor parameters", constructorTypes, constructorArgs);

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id("#" + i);
    // Calculate contract address
    const computedAddress = getCreate2Address({
      salt: salt,

      factoryAddress,
      contractBytecode: contractArtifact.bytecode,
      constructorTypes: constructorTypes,
      constructorArgs: constructorArgs,
    });

    if (computedAddress.startsWith("0x69000")) {
      console.log("found the right salt hash");
      console.log("salt", salt, computedAddress);
      break;
    }

    if (i % 100000 == 0) console.log(i, "salt", salt, computedAddress);
    i++;
  }
};

job();
