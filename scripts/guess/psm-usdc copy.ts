// import
import { ethers } from "ethers";
import { getCreate2Address } from "../create2/create2";

// declare deployment parameters
import contractArtifact from "../../artifacts/contracts/governance/MAHAProxy.sol/MAHAProxy.json";
import implArtificat from "../../artifacts/contracts/core/psm/PegStabilityModule.sol/PegStabilityModule.json";

// @ts-ignore
const constructorTypes = contractArtifact.abi
  .find((v) => v.type === "constructor")
  ?.inputs.map((t) => t.type);

const impl = new ethers.Contract(
  "0x6A661312938D22A2A0e27F585073E4406903990a",
  implArtificat.abi
);

const initData = impl.interface.encodeFunctionData("initialize", [
  "0x69000405f9dce69bd4cbf4f2865b79144a69bfe0", // address _zai,
  "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48", // address _collateral,
  "0x1F09Ec21d7fd0A21879b919bf0f9C46e6b85CA8b", // address _governance,
  1e6, // uint256 _newRate,
  10000000n * 10n ** 6n, // uint256 _supplyCap,
  10000000n * 10n ** 18n, // uint256 _debtCap,
  0, // uint256 _mintFeeBps,
  300, // uint256 _redeemFeeBps,
  "0x6357EDbfE5aDA570005ceB8FAd3139eF5A8863CC", // address _feeDestination
]);

const factoryAddress = "0x21F0F750E2d576AD5d01cFDDcF2095e8DA5b0fb0";
const constructorArgs: any[] = [
  "0x6A661312938D22A2A0e27F585073E4406903990a", // implementation
  "0x6900064e7a3920c114e25b5fe4780f26520e3231", // proxyadmin
  initData, // init data
];

console.log("constructor parameters", constructorTypes, constructorArgs);

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id("" + i);
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
