import { ethers, keccak256 } from "ethers";

export const buildBytecode = (
  constructorTypes: any[],
  constructorArgs: any[],
  contractBytecode: string
) =>
  `${contractBytecode}${encodeParams(constructorTypes, constructorArgs).slice(
    2
  )}`;

const buildCreate2Address = (
  factoryAddress: string,
  saltHex: string,
  byteCode: string
) => {
  return `0x${keccak256(
    `0x${["ff", factoryAddress, saltHex, keccak256(byteCode)]
      .map((x) => x.replace(/0x/, ""))
      .join("")}`
  ).slice(-40)}`.toLowerCase();
};

const saltToHex = (salt: string | number) => ethers.id(salt.toString());

const encodeParams = (dataTypes: any[], data: any[]) => {
  const abiCoder = new ethers.AbiCoder();
  return abiCoder.encode(dataTypes, data);
};

export function getCreate2Address({
  factoryAddress,
  salt,
  contractBytecode,
  constructorTypes = [] as string[],
  constructorArgs = [] as any[],
}: {
  salt: string | number;
  factoryAddress: string;
  contractBytecode: string;
  constructorTypes?: string[];
  constructorArgs?: any[];
}) {
  return buildCreate2Address(
    factoryAddress,
    saltToHex(salt),
    buildBytecode(constructorTypes, constructorArgs, contractBytecode)
  );
}
