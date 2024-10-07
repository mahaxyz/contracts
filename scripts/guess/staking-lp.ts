// import
import { ethers, ZeroAddress } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";
import implArtificat from "../../artifacts/contracts/periphery/staking/StakingLPRewards.sol/StakingLPRewards.json";

// @ts-ignore
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const impl = new ethers.Contract(
  "0x0fDddA590cA26cfa5Cb974b4f3e3991D8348c677",
  implArtificat.abi
);

const initData = impl.interface.encodeFunctionData("initialize", [
  "Staked ZAI/FRAXBP Pool", // string memory _name,
  "sZAIFRAXBP", // string memory _symbol,
  "0x057c658dfbbcbb96c361fb4e66b86cca081b6c6a", // address _stakingToken,
  "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _governance,
  "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _rewardToken1,
  "0x745407c86df8db893011912d3ab28e68b62e49b0", // address _rewardToken2,
  86400 * 7, // uint256 _rewardsDuration,
  ZeroAddress, // address _staking
]);

const factoryAddress = "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0";
const constructorArgs: any[] = [
  impl.target,
  "0x6900064e7a3920c114e25b5fe4780f26520e3231",
  initData,
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
