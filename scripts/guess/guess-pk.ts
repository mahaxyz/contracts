import { encodeRlp, ethers, keccak256 } from "ethers";

const guessAddress = (address: string, index: number) => {
  const nonceHex = index === 0 ? "0x" : ethers.toBeHex(index);
  const encodedData = encodeRlp([ethers.getAddress(address), nonceHex]);
  return `0x${keccak256(encodedData).slice(-40)}`;
};

const job = () => {
  let i = 0;

  while (true) {
    const salt = ethers.id("szai" + i);

    const wallet = new ethers.Wallet(salt);

    // Calculate contract address
    const computedAddress = guessAddress(wallet.address, 0);

    if (computedAddress.startsWith("0x69000")) {
      console.log("found the right salt hash");
      console.log("wallet", wallet.address);
      console.log("pk", salt, computedAddress);
      break;
    }

    if (i % 100000 == 0) console.log(i, "pk", salt, computedAddress);
    i++;
  }
};

job();
