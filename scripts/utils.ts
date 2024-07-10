import { ethers } from "hardhat";
import hre from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Contract, ContractFactory } from "ethers";

export type IState = {
    [key: string]: {
      abi: string;
      address: string;
      txHash: string;
      verification?: string;
    };
};

const skipSave = false;
const ETHERSCAN_URL = "https://sepolia.etherscan.io/";
const state: IState = {};

export async function getDeploymentNonce(signer: SignerWithAddress): Promise<number> {
    return await (signer).getTransactionCount();
}
  
export async function estimateDeploymentAddress(
    address: string,
    nonce: number
): Promise<string> {
    const rlp_encoded = ethers.utils.RLP.encode([
        address,
        ethers.BigNumber.from(nonce.toString()).toHexString(),
    ]);
    
    const contract_address_long = ethers.utils.keccak256(rlp_encoded);
    const contract_address = "0x".concat(contract_address_long.substring(26));
    return ethers.utils.getAddress(contract_address);
}

function getFactory(name: string): Promise<ContractFactory> {
  return ethers.getContractFactory(name);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function deployContract<T extends Contract>(
  name: string,
  params: any[] = []
): Promise<T> {
  console.log(`- Deploying ${name}`);

  const factory = await getFactory(name);
  const contract = (await factory.deploy(...params, {})) as T;

  console.log(`Contract ${name} at ${contract.address}`);

  state[`${name}`] = {
      abi: name,
      address: contract.address,
      txHash: contract.deployTransaction.hash,
  };
  await verify(`${contract.address}`, params);
  sleep(3000);
  return contract;
}

export async function verify(
  contractAddress: string,
  constructorArguments: any[] = []
){
  try {
    console.log(`- Verifying ${contractAddress}`);

    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments: constructorArguments,
    });
  } catch(error) {
    console.log("Verify Error: ", contractAddress);
    console.log(error);
  }
}