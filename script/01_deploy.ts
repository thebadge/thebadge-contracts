import * as dotenv from "dotenv";
import { Contract } from "ethers";
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
  console.log("Deploying Main contracts...");
  const { mainContracts, theBadgeProxy, theBadgeStore } = await deployMainContracts(hre);

  // Deploys all the controllers
  const controllersAddresses = await deployControllers(hre, theBadgeProxy, theBadgeStore);

  console.log("///////// Deployment finished /////////");
  for (const mainContractsAddresses of mainContracts) {
    console.log(`${mainContractsAddresses[0]}-${mainContractsAddresses[1]}`);
  }
  for (const controllerAddress of controllersAddresses) {
    console.log(`${controllerAddress[0]}-${controllerAddress[1]}`);
  }
  console.log("///////// Deployment finished /////////");
}

const deployMainContracts = async (
  hre: HardhatRuntimeEnvironment,
): Promise<{ mainContracts: string[][]; theBadgeProxy: Contract; theBadgeStore: string }> => {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  const contractsAdmin = deployer.address;
  const deployedAddresses = [];

  console.log("Deploying TheBadgeStore...");
  const TheBadgeStore = await ethers.getContractFactory("TheBadgeStore");
  const theBadgeStore = await upgrades.deployProxy(TheBadgeStore, [contractsAdmin, contractsAdmin]);
  await theBadgeStore.deployed();
  console.log(`TheBadgeStore deployed with address: ${theBadgeStore.address}`);
  deployedAddresses.push(["TheBadgeStore", theBadgeStore.address]);
  const theBadgeStoreAddress = theBadgeStore.address;

  console.log("Deploying TheBadgeUsers...");
  const TheBadgeUsers = await ethers.getContractFactory("TheBadgeUsers");
  const theBadgeUsers = await upgrades.deployProxy(TheBadgeUsers, [contractsAdmin, theBadgeStoreAddress]);
  await theBadgeUsers.deployed();
  console.log(`TheBadgeUsers deployed with address: ${theBadgeUsers.address}`);
  deployedAddresses.push(["TheBadgeUsers", theBadgeUsers.address]);

  console.log("Deploying TheBadgeModels...");
  const TheBadgeModels = await ethers.getContractFactory("TheBadgeModels");
  const theBadgeModels = await upgrades.deployProxy(TheBadgeModels, [contractsAdmin, theBadgeStoreAddress]);
  await theBadgeModels.deployed();
  console.log(`TheBadgeModels deployed with address: ${theBadgeModels.address}`);
  deployedAddresses.push(["TheBadgeModels", theBadgeModels.address]);

  console.log("Deploying TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const theBadge = await upgrades.deployProxy(TheBadge, [contractsAdmin, theBadgeStoreAddress]);
  await theBadge.deployed();
  console.log(`TheBadge deployed with address: ${theBadge.address}`);
  deployedAddresses.push(["TheBadge", theBadge.address]);

  console.log("Deploying TheBadgeProxy...");
  const TheBadgeProxy = await ethers.getContractFactory("TheBadgeProxy");
  const theBadgeProxy = await upgrades.deployProxy(TheBadgeProxy, [
    contractsAdmin,
    theBadge.address,
    theBadgeModels.address,
    theBadgeUsers.address,
  ]);
  await theBadge.deployed();
  console.log(`TheBadgeProxy deployed with address: ${theBadge.address}`);
  deployedAddresses.push(["TheBadgeProxy", theBadge.address]);

  console.log("Allowing TheBadge to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadge", theBadge.address);
  console.log("Allowing TheBadgeModels to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeModels", theBadgeModels.address);
  console.log("Allowing TheBadgeUsers to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeUsers", theBadgeUsers.address);

  return { mainContracts: deployedAddresses, theBadgeProxy, theBadgeStore: theBadgeStoreAddress };
};

const deployControllers = async (
  hre: HardhatRuntimeEnvironment,
  theBadge: Contract,
  theBadgeStore: string,
): Promise<string[][]> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];
  console.log("Deploying KlerosBadgeModelController...");
  // Deploys and adds all the controllers
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;
  const klerosBadgeModelController = await upgrades.deployProxy(KlerosBadgeModelController, [
    contractsAdmin,
    theBadge.address,
    klerosArbitror,
    lightGTCRFactory,
    theBadgeStore,
  ]);
  await klerosBadgeModelController.deployed();
  console.log(`KlerosBadgeModelController deployed with address: ${klerosBadgeModelController.address}`);

  console.log("Adding KlerosBadgeModelController to TheBadge...");
  theBadge.connect(deployer);
  await theBadge.addBadgeModelController("kleros", klerosBadgeModelController.address);
  return [["klerosBadgeModelController", klerosBadgeModelController.address]];
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
