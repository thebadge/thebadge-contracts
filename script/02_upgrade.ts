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

  console.log("Upgrading TheBadgeUsersStore...");
  const TheBadgeUsersStore = await ethers.getContractFactory("TheBadgeUsersStore");
  const theBadgeUsersStoreDeployment = contracts.TheBadgeUsersStore.address[chainId as Chains];
  const theBadgeUsersStore = await upgrades.upgradeProxy(theBadgeUsersStoreDeployment, TheBadgeUsersStore);
  await theBadgeUsersStore.deployed();
  console.log(`TheBadgeUsersStore Upgraded with address: ${theBadgeUsersStore.address}`);
  deployedAddresses.push(["TheBadgeUsersStore", theBadgeUsersStore.address]);

  console.log("Upgrading TheBadgeUsers...");
  const TheBadgeUsers = await ethers.getContractFactory("TheBadgeUsers");
  const theBadgeUsersDeployment = contracts.TheBadgeUsers.address[chainId as Chains];
  const theBadgeUsers = await upgrades.upgradeProxy(theBadgeUsersDeployment, TheBadgeUsers);
  await theBadgeUsers.deployed();
  console.log(`TheBadgeUsers Upgraded with address: ${theBadgeUsers.address}`);
  deployedAddresses.push(["TheBadgeUsers", theBadgeUsers.address]);

  console.log("Upgrading TheBadgeModels...");
  const TheBadgeModels = await ethers.getContractFactory("TheBadgeModels");
  const theBadgeModelsDeployment = contracts.TheBadgeModels.address[chainId as Chains];
  const theBadgeModels = await upgrades.upgradeProxy(theBadgeModelsDeployment, TheBadgeModels);
  await theBadgeModels.deployed();
  console.log(`TheBadgeModels Upgraded with address: ${theBadgeModels.address}`);
  deployedAddresses.push(["TheBadgeModels", theBadgeModels.address]);

  console.log("Upgrading TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const theBadgeDeployment = contracts.TheBadge.address[chainId as Chains];
  const theBadge = await upgrades.upgradeProxy(theBadgeDeployment, TheBadge);
  await theBadge.deployed();
  console.log(`TheBadge Upgraded with address: ${theBadge.address}`);
  deployedAddresses.push(["TheBadge", theBadge.address]);

  return deployedAddresses;
};

const upgradeKlerosControllers = async (hre: HardhatRuntimeEnvironment): Promise<string[][]> => {
  const { ethers, network } = hre;
  const chainId = network.config.chainId;

  if (chainId === Chains.polygon) {
    console.warn("Upgrading kleros on Polygon is not allowed, ignoring kleros upgrade...");
    return [];
  }

  console.log("Upgrading KlerosBadgeModelController...");
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  const KlerosBadgeModelControllerDeployment = contracts.KlerosBadgeModelController.address[chainId as Chains];
  const klerosBadgeModelController = await upgrades.upgradeProxy(
    KlerosBadgeModelControllerDeployment,
    KlerosBadgeModelController,
  );
  await klerosBadgeModelController.deployed();

  console.log("Upgrading KlerosBadgeModelControllerStore...");
  const KlerosBadgeModelControllerStore = await ethers.getContractFactory("KlerosBadgeModelControllerStore");
  const klerosBadgeModelControllerStoreDeployment =
    contracts.KlerosBadgeModelControllerStore.address[chainId as Chains];
  const klerosBadgeModelControllerStore = await upgrades.upgradeProxy(
    klerosBadgeModelControllerStoreDeployment,
    KlerosBadgeModelControllerStore,
  );
  await klerosBadgeModelControllerStore.deployed();

  return [
    ["KlerosBadgeModelController", klerosBadgeModelController.address],
    ["KlerosBadgeModelControllerStore", klerosBadgeModelControllerStore.address],
  ];
};

const upgradeThirdPartyControllers = async (hre: HardhatRuntimeEnvironment): Promise<string[][]> => {
  const { ethers, network } = hre;
  const chainId = network.config.chainId;

  console.log("Upgrading TpBadgeModelController...");
  const TpBadgeModelController = await ethers.getContractFactory("TpBadgeModelController");
  const tpBadgeModelControllerDeployment = contracts.TpBadgeModelController.address[chainId as Chains];
  const tpBadgeModelController = await upgrades.upgradeProxy(tpBadgeModelControllerDeployment, TpBadgeModelController);
  await tpBadgeModelController.deployed();

  console.log("Upgrading TpBadgeModelControllerStore...");
  const TpBadgeModelControllerStore = await ethers.getContractFactory("TpBadgeModelControllerStore");
  const tpBadgeModelControllerStoreDeployment = contracts.TpBadgeModelControllerStore.address[chainId as Chains];
  const tpBadgeModelControllerStore = await upgrades.upgradeProxy(
    tpBadgeModelControllerStoreDeployment,
    TpBadgeModelControllerStore,
  );
  await tpBadgeModelController.deployed();

  return [
    ["TpBadgeModelController", tpBadgeModelController.address],
    ["TpBadgeModelControllerStore", tpBadgeModelControllerStore.address],
  ];
};

const updateControllers = async (hre: HardhatRuntimeEnvironment): Promise<string[][]> => {
  const upgradedThirdPartyControllers = await upgradeThirdPartyControllers(hre);
  const upgradedKlerosControllers = await upgradeKlerosControllers(hre);

  return [...upgradedThirdPartyControllers, ...upgradedKlerosControllers];
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
