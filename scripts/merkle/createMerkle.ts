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
  startDate: number;
  endDate: number;
  bonus: number;
};

const parseCSV = async (filePath: string): Promise<UserDetails[]> => {
  return new Promise((resolve, reject) => {
    const results: UserDetails[] = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on("data", (data) => {
        try {
          const userAddress = ethers.getAddress(data.user.toLowerCase()); // Normalize and checksum address

          const userDetails: UserDetails = {
            user: userAddress,
            nftId: parseInt(data.nftId, 10),
            mahaLocked: Number(data.mahaLocked),
            startDate: parseInt(data.startDate, 10),
            endDate: parseInt(data.endDate, 10),
            bonus: Number(data.bonus),
          };

          // Validate the data
          if (
            !ethers.isAddress(userDetails.user) ||
            isNaN(userDetails.nftId) ||
            isNaN(userDetails.mahaLocked) ||
            isNaN(userDetails.startDate) ||
            isNaN(userDetails.endDate) ||
            isNaN(userDetails.bonus)
          ) {
            throw new Error(`Invalid data format: ${JSON.stringify(data)}`);
          }

          if (userDetails.endDate <= userDetails.startDate) {
            throw new Error(`End date must be greater than start date: ${JSON.stringify(data)}`);
          }

          results.push(userDetails);
        } catch (err) {
          console.error("Skipping invalid row:", data, err);
        }
      })
      .on("end", () => resolve(results))
      .on("error", (error) => reject(error));
  });
};

const hashLeafNode = (
  user: string,
  nftId: number,
  mahaLocked: number,
  startDate: number,
  endDate: number,
  bonus: number
): Buffer => {
  return Buffer.from(
    keccak256(
      ethers.AbiCoder.defaultAbiCoder().encode(
        ["address", "uint256", "uint256", "uint256", "uint256", "uint256"],
        [user, nftId, mahaLocked, startDate, endDate, bonus]
      )
    ).substring(2), // Remove the "0x" prefix
    "hex"
  );
};

const generateMerkleTree = (userDetails: UserDetails[]) => {
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

  return {
    root: merkleRoot,
    leaves: userDetails.map((data, index) => ({
      data,
      proof: merkleTree.getHexProof(leafNodes[index]),
    })),
  };
};

async function main() {
  const csvFilePath = path.resolve(__dirname, "./userDetails.csv");
  const outputFilePath = path.resolve(__dirname, "./merkleTreeOutput.json");

  try {
    const userDetails = await parseCSV(csvFilePath);

    if (userDetails.length === 0) {
      throw new Error("No valid data found in the CSV file.");
    }

    const merkleTreeData = generateMerkleTree(userDetails);

    fs.writeFileSync(outputFilePath, JSON.stringify(merkleTreeData, null, 2));
    console.log("Merkle tree written to:", outputFilePath);
  } catch (err) {
    console.error("An error occurred:", err);
    process.exitCode = 1;
  }
}

main();
