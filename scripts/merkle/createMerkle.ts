import { ethers } from "hardhat";
import { MerkleTree } from "merkletreejs";
import fs from "fs";
import path from "path";
import csv from "csv-parser";
import { keccak256 } from "ethers";

type UserDetails = {
  user: string;
  nftId: number;
  mahaLocked: number;
  startDate: string;
  endDate: string;
  bonus: number;
};

const parseCSV = async (filePath: string): Promise<UserDetails[]> => {
  return new Promise((resolve, reject) => {
    const result: UserDetails[] = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on("data", (data) => {
        try {
          const userDetail: UserDetails = {
            user: ethers.getAddress(data.user.toLowerCase()),
            nftId: parseInt(data.nftId, 10),
            mahaLocked: Number(data.mahaLocked),
            startDate: data.startDate,
            endDate: data.endDate,
            bonus: Number(data.bonus),
          };

          if (
            !userDetail.user ||
            isNaN(userDetail.nftId) ||
            isNaN(userDetail.mahaLocked) ||
            !userDetail.startDate ||
            !userDetail.endDate ||
            isNaN(userDetail.bonus)
          ) {
            throw new Error(`Invalid data in ${JSON.stringify(data)}`);
          }

          result.push(userDetail);
        } catch (err) {
          console.error("Error processing row:", data, err);
        }
      })
      .on("end", () => resolve(result))
      .on("error", (error) => reject(error));
  });
};

const hashLeafNode = (
  user: string,
  nftId: number,
  mahaLocked: number,
  startDate: string,
  endDate: string,
  bonus: number
): Buffer => {
  return Buffer.from(
    keccak256(
      ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "uint256", "uint256", "string", "string", "uint256"],
        [user, nftId, mahaLocked, startDate, endDate, bonus]
      )
    ).substring(2), // Remove the "0x" prefix
    "hex"
  );
};

async function main() {
  const csvFilePath = path.resolve(__dirname, "./userDetails.csv");
  const outputFilePath = path.resolve(__dirname, "./merkleTreeOutput.json");

  if (!csvFilePath) {
    throw new Error("Please provide the path to the CSV file as an argument.");
  }

  const userDetails: UserDetails[] = await parseCSV(csvFilePath);

  const leafNodes = userDetails.map((detail) =>
    hashLeafNode(
      detail.user,
      detail.nftId,
      detail.mahaLocked,
      detail.startDate,
      detail.endDate,
      detail.bonus
    )
  );

  const merkleTree = new MerkleTree(leafNodes, keccak256, { sortPairs: true });

  const merkleRoot = merkleTree.getHexRoot();

  console.log("Merkle Tree Root:", merkleRoot);

  const output = {
    root: merkleRoot,
    leaves: userDetails.map((data, index) => ({
      data,
      proof: merkleTree.getHexProof(leafNodes[index]),
    })),
  };

  fs.writeFileSync(outputFilePath, JSON.stringify(output, null, 2));
  console.log("Merkle tree written into:", outputFilePath);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
