interface IGenerateQuoteInput {
  chainId: number;
  inputTokens: {
    tokenAddress: string;
    amount: string;
  }[];
  outputTokens: {
    tokenAddress: string;
    proportion: number;
  }[];
  userAddr: string;
}

interface IGenerateQuoteOutput {
  inTokens: string[];
  outTokens: string[];
  inAmounts: string[];
  outAmounts: string[];
  gasEstimate: number;
  dataGasEstimate: number;
  gweiPerGas: number;
  gasEstimateValue: number;
  inValues: number[];
  outValues: number[];
  netOutValue: number;
  priceImpact: number;
  percentDiff: number;
  partnerFeePercent: number;
  pathId: string;
  pathViz: null;
  blockNumber: number;
}

interface IAssembleTxOuptut {
  deprecated: null;
  blockNumber: number;
  gasEstimate: number;
  gasEstimateValue: number;
  inputTokens: {
    tokenAddress: string;
    amount: string;
  }[];
  outputTokens: {
    tokenAddress: string;
    amount: string;
  }[];
  netOutValue: number;
  outValues: string[];
  transaction: {
    gas: number;
    gasPrice: number;
    value: string;
    to: string;
    from: string;
    data: string;
    nonce: number;
    chainId: number;
  };
  simulation: null;
}

export const generateQuote = async (
  input: IGenerateQuoteInput
): Promise<IGenerateQuoteOutput | undefined> => {
  const quoteUrl = "https://api.odos.xyz/sor/quote/v2";
  const quoteRequestBody = {
    ...input,
    slippageLimitPercent: 1, // set your slippage limit percentage (1 = 1%),
    referralCode: 0, // referral code (recommended)
    disableRFQs: true,
    compact: true,
  };

  console.log(quoteRequestBody);

  const response = await fetch(quoteUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(quoteRequestBody),
  });

  if (response.status === 200) {
    return (await response.json()) as IGenerateQuoteOutput;
  } else {
    console.error("Error in Quote:", response);
  }
};

export const assembleTx = async (
  who: string,
  data: IGenerateQuoteOutput
): Promise<IAssembleTxOuptut | undefined> => {
  const assembleUrl = "https://api.odos.xyz/sor/assemble";

  const assembleRequestBody = {
    userAddr: who, // the checksummed address used to generate the quote
    pathId: data.pathId, // Replace with the pathId from quote response in step 1
    simulate: true, // this can be set to true if the user isn't doing their own estimate gas call for the transaction
  };

  const response = await fetch(assembleUrl, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(assembleRequestBody),
  });

  if (response.status === 200) return await response.json();
  else {
    console.error("Error in Transaction Assembly:", response);
    // handle quote failure cases
  }
};
