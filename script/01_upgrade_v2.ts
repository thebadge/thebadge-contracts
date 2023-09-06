import * as dotenv from "dotenv";
import hre, { upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Chains, contracts, isSupportedNetwork } from "./contracts";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { network } = hre;

  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  // https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
  // https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading-a-contract-via-plugins

  // Deploys the four main contracts: TheBadgeStore, TheBadgeUsers, TheBadgeModels, TheBadge (in that order)

  console.log("Upgrading main contracts...");
  const mainContracts = await upgradeMainContracts(hre);

  // Deploys all the controllers
  const controllersAddresses = await updateControllers(hre);

  console.log("///////// Upgrade finished /////////");
  for (const mainContractsAddresses of mainContracts) {
    console.log(`${mainContractsAddresses[0]}-${mainContractsAddresses[1]}`);
  }
  for (const controllerAddress of controllersAddresses) {
    console.log(`${controllerAddress[0]}-${controllerAddress[1]}`);
  }
  console.log("///////// Upgrade finished /////////");
}

const upgradeMainContracts = async (hre: HardhatRuntimeEnvironment): Promise<string[][]> => {
  const { ethers, network } = hre;
  const chainId = network.config.chainId;
  const deployedAddresses = [];

  console.log("Upgrading TheBadgeStore...");
  const TheBadgeStore = await ethers.getContractFactory("TheBadgeStore");
  const theBadgeStoreDeployment = contracts.TheBadgeStore.address[chainId as Chains];
  const theBadgeStore = await upgrades.upgradeProxy(theBadgeStoreDeployment, TheBadgeStore);
  await theBadgeStore.deployed();
  console.log(`TheBadgeStore Upgraded with address: ${theBadgeStore.address}`);
  deployedAddresses.push(["TheBadgeStore", theBadgeStore.address]);

  console.log("Upgrading TheBadgeUsers...");
  const TheBadgeUsers = await ethers.getContractFactory("TheBadgeUsersFacet");
  const theBadgeUsersDeployment = contracts.TheBadgeUsers.address[chainId as Chains];
  const theBadgeUsers = await upgrades.upgradeProxy(theBadgeUsersDeployment, TheBadgeUsers);
  await theBadgeUsers.deployed();
  console.log(`TheBadgeUsers Upgraded with address: ${theBadgeUsers.address}`);
  deployedAddresses.push(["TheBadgeUsers", theBadgeUsers.address]);

  console.log("Upgrading TheBadgeModels...");
  const TheBadgeModels = await ethers.getContractFactory("TheBadgeModelsFacet");
  const theBadgeModelsDeployment = contracts.TheBadgeModels.address[chainId as Chains];
  const theBadgeModels = await upgrades.upgradeProxy(theBadgeModelsDeployment, TheBadgeModels);
  await theBadgeModels.deployed();
  console.log(`TheBadgeModels Upgraded with address: ${theBadgeModels.address}`);
  deployedAddresses.push(["TheBadgeModels", theBadgeModels.address]);

  console.log("Upgrading TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadgeFacet");
  const theBadgeDeployment = contracts.TheBadge.address[chainId as Chains];
  const theBadge = await upgrades.upgradeProxy(theBadgeDeployment, TheBadge);
  await theBadge.deployed();
  console.log(`TheBadge Upgraded with address: ${theBadge.address}`);
  deployedAddresses.push(["TheBadge", theBadge.address]);

  return deployedAddresses;
};

const updateControllers = async (hre: HardhatRuntimeEnvironment): Promise<string[][]> => {
  const { ethers, network } = hre;

  const chainId = network.config.chainId;

  console.log("Upgrading KlerosBadgeModelController...");
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  const KlerosBadgeModelControllerDeployment = contracts.KlerosBadgeModelController.address[chainId as Chains];
  const klerosBadgeModelController = await upgrades.upgradeProxy(
    KlerosBadgeModelControllerDeployment,
    KlerosBadgeModelController,
  );
  await klerosBadgeModelController.deployed();

  return [["klerosBadgeModelController", klerosBadgeModelController.address]];
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
