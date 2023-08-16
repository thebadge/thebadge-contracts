import * as dotenv from "dotenv";
import { run } from "hardhat";

dotenv.config();

// Todo refactor to something more fancy
const { GOERLI_THE_BADGE_CONTRACT_ADDRESS, GOERLI_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS } = process.env;
if (!GOERLI_THE_BADGE_CONTRACT_ADDRESS || !GOERLI_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS) {
  throw new Error(`Contract addresses not set!`);
}
const theBadgeDeployedAddress = GOERLI_THE_BADGE_CONTRACT_ADDRESS;
const klerosBadgeModelControllerDeployedAddress = GOERLI_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS;

async function main() {
  console.log("Verifying TheBadge contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosBadgeModelControllerDeployedAddress,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
