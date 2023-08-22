import * as dotenv from "dotenv";
import hre, { run } from "hardhat";
import { Chains, contracts, isSupportedNetwork } from "./contracts";

dotenv.config();

async function main() {
  const { network } = hre;
  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }
  const theBadgeDeployedAddress = contracts.TheBadge.address[chainId as Chains];
  const klerosBadgeModelControllerDeployedAddress = contracts.KlerosBadgeModelController.address[chainId as Chains];
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
