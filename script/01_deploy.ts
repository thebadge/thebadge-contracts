import * as dotenv from "dotenv";
import { Contract, utils } from "ethers";
import { keccak256 } from "ethers/lib/utils";
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
  const { mainContracts, theBadge, theBadgeUsers, theBadgeModels, theBadgeUsersStore } = await deployMainContracts(hre);

  // Deploys all the controllers
  const controllersAddresses = await deployControllers(hre, {
    theBadge,
    theBadgeModels,
    theBadgeUsers,
    theBadgeUsersStore,
  });

  console.log("///////// Deployment finished /////////");
  for (const mainContractsAddresses of mainContracts) {
    console.log(`${mainContractsAddresses[0]}: ${mainContractsAddresses[1]}`);
  }
  for (const controllerAddress of controllersAddresses) {
    console.log(`${controllerAddress[0]}: ${controllerAddress[1]}`);
  }
  console.log("///////// Deployment finished /////////");
}

const deployMainContracts = async (
  hre: HardhatRuntimeEnvironment,
): Promise<{
  mainContracts: string[][];
  theBadge: any;
  theBadgeModels: any;
  theBadgeUsers: any;
  theBadgeUsersStore: any;
}> => {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  const contractsAdmin = deployer.address;
  const deployedAddresses = [];

  console.log("Deploying TheBadgeStore...");
  const TheBadgeStore = await ethers.getContractFactory("TheBadgeStore");
  const theBadgeStore = await upgrades.deployProxy(TheBadgeStore, [contractsAdmin, contractsAdmin]);
  await theBadgeStore.deployed();
  const theBadgeStoreAddress = theBadgeStore.address;
  console.log(`TheBadgeStore deployed with address: ${theBadgeStoreAddress}`);

  console.log("Deploying TheBadgeUsersStore...");
  const TheBadgeUsersStore = await ethers.getContractFactory("TheBadgeUsersStore");
  const theBadgeUsersStore = await upgrades.deployProxy(TheBadgeUsersStore, [contractsAdmin]);
  await theBadgeUsersStore.deployed();
  const theBadgeUsersStoreAddress = theBadgeUsersStore.address;
  console.log(`TheBadgeUsersStore deployed with address: ${theBadgeUsersStoreAddress}`);

  console.log("Deploying TheBadgeUsers...");
  const TheBadgeUsers = await ethers.getContractFactory("TheBadgeUsers");
  const theBadgeUsers = await upgrades.deployProxy(TheBadgeUsers, [
    contractsAdmin,
    theBadgeStoreAddress,
    theBadgeUsersStoreAddress,
  ]);
  await theBadgeUsers.deployed();
  const theBadgeUsersAddress = theBadgeUsers.address;
  console.log(`TheBadgeUsers deployed with address: ${theBadgeUsersAddress}`);

  console.log("Deploying TheBadgeModels...");
  const TheBadgeModels = await ethers.getContractFactory("TheBadgeModels");
  const theBadgeModels = await upgrades.deployProxy(TheBadgeModels, [
    contractsAdmin,
    theBadgeStoreAddress,
    theBadgeUsersAddress,
  ]);
  await theBadgeModels.deployed();
  const theBadgeModelsAddress = theBadgeModels.address;
  console.log(`TheBadgeModels deployed with address: ${theBadgeModelsAddress}`);

  console.log("Deploying TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const theBadge = await upgrades.deployProxy(TheBadge, [contractsAdmin, theBadgeStoreAddress, theBadgeUsersAddress]);
  await theBadge.deployed();
  const theBadgeAddress = theBadge.address;
  console.log(`TheBadge deployed with address: ${theBadgeAddress}`);

  console.log("Grant userManager role to TheBadgeModels on TheBadgeUsers...");
  const managerRole = keccak256(utils.toUtf8Bytes("USER_MANAGER_ROLE"));
  await theBadgeUsers.grantRole(managerRole, theBadgeModels.address);

  deployedAddresses.push(["TheBadge", theBadgeAddress]);
  deployedAddresses.push(["TheBadgeStore", theBadgeStoreAddress]);
  deployedAddresses.push(["TheBadgeUsersStore", theBadgeUsersStoreAddress]);
  deployedAddresses.push(["TheBadgeUsers", theBadgeUsersAddress]);
  deployedAddresses.push(["TheBadgeModels", theBadgeModelsAddress]);

  console.log("Allowing TheBadge to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadge", theBadgeAddress);
  console.log("Allowing TheBadgeModels to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeModels", theBadgeModelsAddress);
  console.log("Allowing TheBadgeUsers to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeUsers", theBadgeUsersAddress);

  console.log("Allowing TheBadgeUsers to access TheBadgeUsersStore...");
  await theBadgeUsersStore.addPermittedContract("TheBadgeUsers", theBadgeUsersAddress);

  return {
    mainContracts: deployedAddresses,
    theBadge,
    theBadgeModels,
    theBadgeUsers,
    theBadgeUsersStore,
  };
};

const deployControllers = async (
  hre: HardhatRuntimeEnvironment,
  {
    theBadge,
    theBadgeModels,
    theBadgeUsers,
  }: {
    theBadge: Contract;
    theBadgeModels: Contract;
    theBadgeUsers: Contract;
    theBadgeUsersStore: Contract;
  },
): Promise<string[][]> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];
  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;

  console.log("Deploying KlerosBadgeModelControllerStore...");
  const KlerosBadgeModelControllerStore = await ethers.getContractFactory("KlerosBadgeModelControllerStore");
  const klerosBadgeModelControllerStore = await upgrades.deployProxy(KlerosBadgeModelControllerStore, [
    contractsAdmin,
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await klerosBadgeModelControllerStore.deployed();
  console.log(`KlerosBadgeModelControllerStore deployed with address: ${klerosBadgeModelControllerStore.address}`);

  console.log("Deploying KlerosBadgeModelController...");
  // Deploys and adds all the controllers
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  const klerosBadgeModelController = await upgrades.deployProxy(KlerosBadgeModelController, [
    contractsAdmin,
    theBadge.address,
    theBadgeModels.address,
    klerosBadgeModelControllerStore.address,
  ]);
  await klerosBadgeModelController.deployed();
  console.log(`KlerosBadgeModelController deployed with address: ${klerosBadgeModelController.address}`);

  console.log("Allowing KlerosBadgeModelController to access KlerosBadgeModelControllerStore...");
  await klerosBadgeModelControllerStore.addPermittedContract(
    "KlerosBadgeModelController",
    klerosBadgeModelController.address,
  );

  console.log("Adding KlerosBadgeModelController to TheBadge...");
  theBadgeModels.connect(deployer);
  await theBadgeModels.addBadgeModelController("kleros", klerosBadgeModelController.address);

  console.log("Deploying ThirdPartyModelControllerStore...");
  const TpBadgeModelControllerStore = await ethers.getContractFactory("TpBadgeModelControllerStore");
  const tpBadgeModelControllerStore = await upgrades.deployProxy(TpBadgeModelControllerStore, [
    contractsAdmin,
    contractsAdmin,
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await tpBadgeModelControllerStore.deployed();
  console.log(`ThirdPartyModelControllerStore deployed with address: ${tpBadgeModelControllerStore.address}`);

  console.log("Deploying ThirdPartyModelController...");
  const TpBadgeModelController = await ethers.getContractFactory("TpBadgeModelController");
  const tpBadgeModelController = await upgrades.deployProxy(TpBadgeModelController, [
    contractsAdmin,
    theBadge.address,
    theBadgeModels.address,
    tpBadgeModelControllerStore.address,
    theBadgeUsers.address,
  ]);
  await tpBadgeModelController.deployed();
  console.log(`ThirdPartyModelController deployed with address: ${tpBadgeModelController.address}`);

  console.log("Allowing ThirdPartyModelController to access TpBadgeModelControllerSTore...");
  await tpBadgeModelControllerStore.addPermittedContract("TpBadgeModelController", tpBadgeModelController.address);

  console.log(`Grant claimer role to the relayer address: ${contractsAdmin} on ThirdPartyModelControllerStore...`);
  const claimerRole = keccak256(utils.toUtf8Bytes("CLAIMER_ROLE"));
  await tpBadgeModelController.grantRole(claimerRole, contractsAdmin);

  console.log("Adding ThirdPartyModelController to TheBadge...");
  theBadgeModels.connect(deployer);
  await theBadgeModels.addBadgeModelController("thirdParty", tpBadgeModelController.address);

  return [
    ["klerosBadgeModelController", klerosBadgeModelController.address],
    ["klerosBadgeModelControllerStore", klerosBadgeModelControllerStore.address],
    ["ThirdPartyModelController", tpBadgeModelController.address],
    ["TpBadgeModelControllerStore", tpBadgeModelControllerStore.address],
  ];
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
