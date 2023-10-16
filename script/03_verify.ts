import * as dotenv from "dotenv";
import hre, { run, tenderly, ethers } from "hardhat";
import { Chains, contracts, isSupportedNetwork } from "./contracts";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

dotenv.config();

async function main() {
  const { network } = hre;
  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  const theBadgeDeployedAddress = contracts.TheBadge.address[chainId as Chains];
  const theBadgeStore = contracts.TheBadgeStore.address[chainId as Chains];
  const theBadgeUsers = contracts.TheBadgeUsers.address[chainId as Chains];
  const theBadgeModels = contracts.TheBadgeModels.address[chainId as Chains];
  const klerosBadgeModelControllerDeployedAddress = contracts.KlerosBadgeModelController.address[chainId as Chains];
  const klerosBadgeModelControllerStoreDeployedAddress =
    contracts.KlerosBadgeModelControllerStore.address[chainId as Chains];
  const tpBadgeModelControllerDeployedAddress = contracts.TpBadgeModelController.address[chainId as Chains];
  const tpBadgeModelControllerStoreDeployedAddress = contracts.TpBadgeModelControllerStore.address[chainId as Chains];

  console.log("Verifying TheBadge contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying TheBadgeStore contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeStore,
    constructorArguments: [],
  });

  console.log("Verifying TheBadgeUsers contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeUsers,
    constructorArguments: [],
  });

  console.log("Verifying TheBadgeModels contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeModels,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosBadgeModelControllerDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelControllerStore contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosBadgeModelControllerStoreDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying TpBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: tpBadgeModelControllerDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying tpBadgeModelControllerStore contract on Etherscan...");
  await run(`verify:verify`, {
    address: tpBadgeModelControllerStoreDeployedAddress,
    constructorArguments: [],
  });

  // Verify on tenderly
  console.log("Verifying contracts on Tenderly...");
  const deployedContracts = [
    {
      name: "TheBadge",
      address: await getImplementationAddress(ethers.provider, theBadgeDeployedAddress),
      network: chainId.toString(),
    },
    {
      name: "TheBadgeStore",
      address: await getImplementationAddress(ethers.provider, theBadgeStore),
      network: chainId.toString(),
    },
    {
      name: "TheBadgeUsers",
      address: await getImplementationAddress(ethers.provider, theBadgeUsers),
      network: chainId.toString(),
    },
    {
      name: "TheBadgeModels",
      address: await getImplementationAddress(ethers.provider, theBadgeModels),
      network: chainId.toString(),
    },
    {
      name: "KlerosBadgeModelController",
      address: await getImplementationAddress(ethers.provider, klerosBadgeModelControllerDeployedAddress),
      network: chainId.toString(),
    },
    {
      name: "KlerosBadgeModelControllerStore",
      address: await getImplementationAddress(ethers.provider, klerosBadgeModelControllerStoreDeployedAddress),
      network: chainId.toString(),
    },
    {
      name: "TpBadgeModelController",
      address: await getImplementationAddress(ethers.provider, tpBadgeModelControllerDeployedAddress),
      network: chainId.toString(),
    },
    {
      name: "TpBadgeModelControllerStore",
      address: await getImplementationAddress(ethers.provider, tpBadgeModelControllerStoreDeployedAddress),
      network: chainId.toString(),
    },
  ];
  await tenderly.verify(...deployedContracts);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
