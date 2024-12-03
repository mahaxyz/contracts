import { assembleTx, generateQuote } from "./odos";

export const getGelatoCode = async (
  chainId: number,
  targetToken: string,
  contract: string,
  balances: string[],
  tokenAddresses: readonly `0x${string}`[]
) => {
  const hasBalance =
    balances.findIndex((v) => v !== "0" && v !== "" && !!v) >= 0;
  if (!hasBalance) throw new Error("no balance");

  // get quote from odos
  const quote = await generateQuote({
    chainId: chainId,
    inputTokens: tokenAddresses
      .map((t, i) => ({
        tokenAddress: t,
        amount: balances[i].toString(),
      }))
      .filter((p) => p.tokenAddress.toLowerCase() != targetToken.toLowerCase())
      .filter((p) => p.amount !== "0"),
    outputTokens: [
      {
        tokenAddress: targetToken,
        proportion: 1,
      },
    ],
    userAddr: contract,
  });

  if (!quote) throw new Error("invalid quote from odos");

  // prepare tx from odos
  const txData = await assembleTx(contract, quote);
  if (!txData) throw new Error("invalid assemble from odos");

  console.log("data", txData.transaction.data);

  return txData.transaction;
};
