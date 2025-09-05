import hre from "hardhat";
import fs from "fs";
import path from "path";
import csv from "csv-parser";
import { waitForTx } from "../utils";

async function main() {
  const { deployments } = hre;
  
  // Get deployed contracts
  const lockerTokenD = await deployments.get("LockerToken-V3-Proxy");
  const newLocker = await hre.ethers.getContractAt(
    "LockerToken",
    lockerTokenD.address
  );

  console.log("Starting migration process from locker-snapshot.csv...");

  const results: {
    token: string;
    amount: string;
    start: string;
    end: string;
    owner: string;
    stakednft: string;
  }[] = [];

  // Read CSV file
  fs.createReadStream(path.resolve(__dirname, "locker-snapshot.csv"))
    .pipe(csv())
    .on("data", (data) => results.push(data))
    .on("end", async () => {
      console.log(`Found ${results.length} tokens in CSV file`);

      // Arrays to store migration data
      const tokenIds: bigint[] = [];
      const values: bigint[] = [];
      const starts: bigint[] = [];
      const ends: bigint[] = [];
      const owners: string[] = [];
      const stakeNFTs: boolean[] = [];

      // Cache current timestamp to compute durations
      const latestBlock = await hre.ethers.provider.getBlock("latest");
      
      // Process CSV data in parallel chunks
      const chunkSize = 100;
      const chunks: typeof results[] = [];
      for (let i = 0; i < results.length; i += chunkSize) {
        chunks.push(results.slice(i, i + chunkSize));
      }
      
      console.log(`Processing ${results.length} tokens in ${chunks.length} parallel chunks...`);
      
      const processedChunks = await Promise.all(
        chunks.map((chunk: typeof results, chunkIndex: number) => 
          Promise.resolve().then(() => {
            const chunkTokenIds: bigint[] = [];
            const chunkValues: bigint[] = [];
            const chunkStarts: bigint[] = [];
            const chunkEnds: bigint[] = [];
            const chunkOwners: string[] = [];
            const chunkStakeNFTs: boolean[] = [];
            
            for (let i = 0; i < chunk.length; i++) {
              const result = chunk[i];
              
              // Skip invalid entries
              if (!result.amount || result.amount === "0") {
                continue;
              }
              
              if (!result.owner || result.owner === "0x0000000000000000000000000000000000000000") {
                console.log(`Skipping token ${result.token}: invalid owner`);
                continue;
              }
              
              const start = BigInt(result.start);
              const end = BigInt(result.end);
              const amount = BigInt(result.amount);
              const shouldStake = result.stakednft === "true";
              const tokenId = BigInt(result.token);

              chunkTokenIds.push(tokenId);
              chunkValues.push(amount);
              chunkStarts.push(start);
              chunkEnds.push(end);
              chunkOwners.push(result.owner);
              chunkStakeNFTs.push(shouldStake);
            }

            console.log(`Chunk ${chunkIndex + 1}/${chunks.length} processed: ${chunkTokenIds.length} valid tokens`);
            
            return {
              tokenIds: chunkTokenIds,
              values: chunkValues,
              starts: chunkStarts,
              ends: chunkEnds,
              owners: chunkOwners,
              stakeNFTs: chunkStakeNFTs
            };
          })
        )
      );

      // Merge all processed chunks
      for (const chunk of processedChunks) {
        tokenIds.push(...chunk.tokenIds);
        values.push(...chunk.values);
        starts.push(...chunk.starts);
        ends.push(...chunk.ends);
        owners.push(...chunk.owners);
        stakeNFTs.push(...chunk.stakeNFTs);
      }

      console.log(`\nPrepared ${values.length} valid tokens for migration`);

      if (values.length === 0) {
        console.log("No valid tokens to migrate!");
        return;
      }

      // Execute migration in batches to avoid gas limit issues
      const batchSize = 100;

      for (let i = 0; i < values.length; i += batchSize) {
        const batchEnd = Math.min(i + batchSize, values.length);
        const batchTokenIds = tokenIds.slice(i, batchEnd);
        const batchValues = values.slice(i, batchEnd);
        const batchStarts = starts.slice(i, batchEnd);
        const batchEnds = ends.slice(i, batchEnd);
        const batchOwners = owners.slice(i, batchEnd);
        const batchStakeNFTs = stakeNFTs.slice(i, batchEnd);

        console.log(`Migrating tokens ${i + 1} to ${batchEnd}`);

        // Execute the migration directly
        const tx = await newLocker.migrateLocks(
          batchTokenIds,
          batchValues,
          batchStarts,
          batchEnds,
          batchOwners,
          batchStakeNFTs
        );

        await waitForTx(tx);
        console.log(`✅ Batch ${Math.floor(i / batchSize) + 1} executed successfully`);
      }

      console.log("\n✅ Migration completed successfully!");
    });
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
