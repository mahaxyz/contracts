import implArtificat from "../../artifacts/contracts/governance/MAHATimelockController.sol/MAHATimelockController.json";
import { guess } from "./_helpers";

guess(
  implArtificat,
  [
    60 * 60,
    "0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b",
    ["0x1f09ec21d7fd0a21879b919bf0f9c46e6b85ca8b"],
  ],
  "mainnet"
);
