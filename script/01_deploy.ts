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
  const { mainContracts, theBadge, theBadgeUsers, theBadgeModels } = await deployMainContracts(hre);

  // Deploys all the controllers
  const controllersAddresses = await deployControllers(hre, { theBadge, theBadgeModels, theBadgeUsers });

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
}> => {
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
  const theBadgeModels = await upgrades.deployProxy(TheBadgeModels, [
    contractsAdmin,
    theBadgeStoreAddress,
    theBadgeUsers.address,
  ]);
  await theBadgeModels.deployed();
  console.log(`TheBadgeModels deployed with address: ${theBadgeModels.address}`);
  deployedAddresses.push(["TheBadgeModels", theBadgeModels.address]);

  console.log("Deploying TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const theBadge = await upgrades.deployProxy(TheBadge, [contractsAdmin, theBadgeStoreAddress]);
  await theBadge.deployed();
  console.log(`TheBadge deployed with address: ${theBadge.address}`);
  deployedAddresses.push(["TheBadge", theBadge.address]);

  console.log("Allowing TheBadge to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadge", theBadge.address);
  console.log("Allowing TheBadgeModels to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeModels", theBadgeModels.address);
  console.log("Allowing TheBadgeUsers to access TheBadgeStore...");
  await theBadgeStore.addPermittedContract("TheBadgeUsers", theBadgeUsers.address);
  console.log("Grant userManager role to TheBadgeModels on TheBadgeUsers...");
  const managerRole = keccak256(utils.toUtf8Bytes("USER_MANAGER_ROLE"));
  await theBadgeUsers.grantRole(managerRole, theBadgeModels.address);

  return {
    mainContracts: deployedAddresses,
    theBadge,
    theBadgeModels,
    theBadgeUsers,
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
  },
): Promise<string[][]> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];
  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;

  console.log("Deploying KlerosBadgeModelController...");
  // Deploys and adds all the controllers
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  const klerosBadgeModelController = await upgrades.deployProxy(KlerosBadgeModelController, [
    contractsAdmin,
    "0x24a2cC73D3b33fa92B9dc299835ec3715FB033fB",
    "0x17179b1c18AB35c78C95dE4c57eDb08b6286D60a",
    "0x1e2D6FCF076726049F5554f848Fc332c052e0e5b",
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await klerosBadgeModelController.deployed();
  console.log(`KlerosBadgeModelController deployed with address: ${klerosBadgeModelController.address}`);

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
    theBadgeUsers.address,
    tpBadgeModelControllerStore.address,
  ]);
  await tpBadgeModelController.deployed();
  console.log(`ThirdPartyModelController deployed with address: ${tpBadgeModelController.address}`);

  console.log("Allowing ThirdPartyModelController to access ThirdPartyModelControllerStore...");
  await tpBadgeModelControllerStore.addPermittedContract("TpBadgeModelController", tpBadgeModelController.address);

  console.log(`Grant claimer role to the relayer address: ${contractsAdmin} on ThirdPartyModelControllerStore...`);
  const claimerRole = keccak256(utils.toUtf8Bytes("CLAIMER_ROLE"));
  await tpBadgeModelController.grantRole(claimerRole, contractsAdmin);

  console.log("Adding ThirdPartyModelController to TheBadge...");
  theBadgeModels.connect(deployer);
  await theBadgeModels.addBadgeModelController("thirdParty", tpBadgeModelController.address);

  return [
    ["klerosBadgeModelController", klerosBadgeModelController.address],
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
