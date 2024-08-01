import { executeCreate2 } from "./helpers";

async function main() {
  await executeCreate2(
    "XERC20-impl",
    "XERC20",
    [],
    "arbitrum",
    "0x52e810aa739c078a8b372f3e003efabc56ca497a06da279dbbc060bed8345146",
    "0xf1adca6863abe2fa5592c7220e5053b42a94e298"
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
