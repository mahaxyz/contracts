import implArtificat from "../../artifacts/contracts/periphery/connext/XERC20.sol/XERC20.json";
import { get, guessProxy } from "./_helpers";

guessProxy(
  implArtificat,
  get("XERC20-impl", "arbitrum"),
  "initialize",
  [
    "ZAI Stablecoin",
    "USDz",
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b", // admin
  ],
  "arbitrum"
);
