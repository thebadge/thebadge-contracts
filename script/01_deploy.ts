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
  const { mainContracts, theBadge, theBadgeUsers, theBadgeModels, theBadgeUsersStore, theBadgeStore } =
    await deployMainContracts(hre);

  // Deploys all the controllers
  const {
    controllersAddresses,
    tpBadgeModelControllerStore,
    klerosBadgeModelControllerStore,
    tpBadgeModelController,
    klerosBadgeModelController,
  } = await deployControllers(hre, {
    theBadge,
    theBadgeModels,
    theBadgeUsers,
    theBadgeUsersStore,
  });

  // Configure all the permissions
  await configurePermissions(hre, {
    theBadge,
    theBadgeModels,
    theBadgeUsers,
    theBadgeUsersStore,
    tpBadgeModelController,
    klerosBadgeModelController,
    klerosBadgeModelControllerStore,
    tpBadgeModelControllerStore,
    theBadgeStore,
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
  theBadgeStore: any;
  theBadgeModels: any;
  theBadgeUsers: any;
  theBadgeUsersStore: any;
}> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  const contractsAdmin = deployer.address;
  const deployedAddresses = [];

  console.log("Deploying TheBadgeStore...");
  const TheBadgeStore = await ethers.getContractFactory("TheBadgeStore");
  const theBadgeStore = contracts.TheBadgeStore.address[chainId as Chains]
    ? TheBadgeStore.attach(contracts.TheBadgeStore.address[chainId as Chains])
    : await upgrades.deployProxy(TheBadgeStore, [contractsAdmin, contractsAdmin]);
  await theBadgeStore.deployed();
  const theBadgeStoreAddress = theBadgeStore.address;
  console.log(`TheBadgeStore deployed with address: ${theBadgeStoreAddress}`);

  console.log("Deploying TheBadgeUsersStore...");
  const TheBadgeUsersStore = await ethers.getContractFactory("TheBadgeUsersStore");
  const theBadgeUsersStore = contracts.TheBadgeUsersStore.address[chainId as Chains]
    ? TheBadgeUsersStore.attach(contracts.TheBadgeUsersStore.address[chainId as Chains])
    : await upgrades.deployProxy(TheBadgeUsersStore, [contractsAdmin]);
  await theBadgeUsersStore.deployed();
  const theBadgeUsersStoreAddress = theBadgeUsersStore.address;
  console.log(`TheBadgeUsersStore deployed with address: ${theBadgeUsersStoreAddress}`);

  console.log("Deploying TheBadgeUsers...");
  const TheBadgeUsers = await ethers.getContractFactory("TheBadgeUsers");
  const theBadgeUsers = contracts.TheBadgeUsers.address[chainId as Chains]
    ? TheBadgeUsers.attach(contracts.TheBadgeUsers.address[chainId as Chains])
    : await upgrades.deployProxy(TheBadgeUsers, [contractsAdmin, theBadgeStoreAddress, theBadgeUsersStoreAddress]);
  await theBadgeUsers.deployed();
  const theBadgeUsersAddress = theBadgeUsers.address;
  console.log(`TheBadgeUsers deployed with address: ${theBadgeUsersAddress}`);

  console.log("Deploying TheBadgeModels...");
  const TheBadgeModels = await ethers.getContractFactory("TheBadgeModels");

  const theBadgeModels = contracts.TheBadgeModels.address[chainId as Chains]
    ? TheBadgeModels.attach(contracts.TheBadgeModels.address[chainId as Chains])
    : await upgrades.deployProxy(TheBadgeModels, [contractsAdmin, theBadgeStoreAddress, theBadgeUsersAddress]);
  await theBadgeModels.deployed();
  const theBadgeModelsAddress = theBadgeModels.address;
  console.log(`TheBadgeModels deployed with address: ${theBadgeModelsAddress}`);

  console.log("Deploying TheBadge...");
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const theBadge = contracts.TheBadge.address[chainId as Chains]
    ? TheBadge.attach(contracts.TheBadge.address[chainId as Chains])
    : await upgrades.deployProxy(TheBadge, [contractsAdmin, theBadgeStoreAddress, theBadgeUsersAddress]);
  await theBadge.deployed();
  const theBadgeAddress = theBadge.address;
  console.log(`TheBadge deployed with address: ${theBadgeAddress}`);

  deployedAddresses.push(["TheBadge", theBadgeAddress]);
  deployedAddresses.push(["TheBadgeStore", theBadgeStoreAddress]);
  deployedAddresses.push(["TheBadgeUsersStore", theBadgeUsersStoreAddress]);
  deployedAddresses.push(["TheBadgeUsers", theBadgeUsersAddress]);
  deployedAddresses.push(["TheBadgeModels", theBadgeModelsAddress]);

  return {
    mainContracts: deployedAddresses,
    theBadge,
    theBadgeStore,
    theBadgeModels,
    theBadgeUsers,
    theBadgeUsersStore,
  };
};

const deployKlerosControllers = async (
  hre: HardhatRuntimeEnvironment,
  {
    theBadge,
    theBadgeModels,
  }: {
    theBadge: Contract;
    theBadgeModels: Contract;
  },
): Promise<{
  klerosControllers: string[][];
  klerosBadgeModelController: any;
  klerosBadgeModelControllerStore: any;
}> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;

  if (chainId === Chains.polygon || chainId == Chains.mumbai) {
    console.warn("Deploy kleros on Polygon is not allowed, ignoring kleros deployment...");
    return {
      klerosControllers: [],
      klerosBadgeModelController: null,
      klerosBadgeModelControllerStore: null,
    };
  }
  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];

  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;

  console.log("Deploying KlerosBadgeModelControllerStore...");
  const KlerosBadgeModelControllerStore = await ethers.getContractFactory("KlerosBadgeModelControllerStore");
  const klerosBadgeModelControllerStore = contracts.KlerosBadgeModelControllerStore.address[chainId as Chains]
    ? KlerosBadgeModelControllerStore.attach(contracts.KlerosBadgeModelControllerStore.address[chainId as Chains])
    : await upgrades.deployProxy(KlerosBadgeModelControllerStore, [contractsAdmin, klerosArbitror, lightGTCRFactory]);
  await klerosBadgeModelControllerStore.deployed();
  console.log(`KlerosBadgeModelControllerStore deployed with address: ${klerosBadgeModelControllerStore.address}`);

  console.log("Deploying KlerosBadgeModelController...");
  // Deploys and adds all the controllers
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");
  const klerosBadgeModelController = contracts.KlerosBadgeModelController.address[chainId as Chains]
    ? KlerosBadgeModelController.attach(contracts.KlerosBadgeModelController.address[chainId as Chains])
    : await upgrades.deployProxy(KlerosBadgeModelController, [
        contractsAdmin,
        theBadge.address,
        theBadgeModels.address,
        klerosBadgeModelControllerStore.address,
      ]);
  await klerosBadgeModelController.deployed();
  console.log(`KlerosBadgeModelController deployed with address: ${klerosBadgeModelController.address}`);

  return {
    klerosControllers: [
      ["klerosBadgeModelController", klerosBadgeModelController.address],
      ["klerosBadgeModelControllerStore", klerosBadgeModelControllerStore.address],
    ],
    klerosBadgeModelController,
    klerosBadgeModelControllerStore,
  };
};

const deployThirdPartyControllers = async (
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
): Promise<{
  tpControllers: string[][];
  tpBadgeModelController: any;
  tpBadgeModelControllerStore: any;
}> => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  console.log(`Deploying thirdPartyControllers on chain: ${chainId}...`);

  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;

  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];

  console.log("Deploying ThirdPartyModelControllerStore...");
  const TpBadgeModelControllerStore = await ethers.getContractFactory("TpBadgeModelControllerStore");
  const tpBadgeModelControllerStore = contracts.TpBadgeModelControllerStore.address[chainId as Chains]
    ? TpBadgeModelControllerStore.attach(contracts.TpBadgeModelControllerStore.address[chainId as Chains])
    : await upgrades.deployProxy(TpBadgeModelControllerStore, [
        contractsAdmin,
        contractsAdmin,
        klerosArbitror,
        lightGTCRFactory,
      ]);

  await tpBadgeModelControllerStore.deployed();
  console.log(`ThirdPartyModelControllerStore deployed with address: ${tpBadgeModelControllerStore.address}`);

  console.log("Deploying ThirdPartyModelController...");
  const TpBadgeModelController = await ethers.getContractFactory("TpBadgeModelController");
  const tpBadgeModelController = contracts.TpBadgeModelController.address[chainId as Chains]
    ? TpBadgeModelControllerStore.attach(contracts.TpBadgeModelController.address[chainId as Chains])
    : await upgrades.deployProxy(TpBadgeModelController, [
        contractsAdmin,
        theBadge.address,
        theBadgeModels.address,
        tpBadgeModelControllerStore.address,
        theBadgeUsers.address,
      ]);
  await tpBadgeModelController.deployed();
  console.log(`ThirdPartyModelController deployed with address: ${tpBadgeModelController.address}`);

  return {
    tpControllers: [
      ["ThirdPartyModelController", tpBadgeModelController.address],
      ["TpBadgeModelControllerStore", tpBadgeModelControllerStore.address],
    ],
    tpBadgeModelController,
    tpBadgeModelControllerStore,
  };
};

const configurePermissions = async (
  hre: HardhatRuntimeEnvironment,
  {
    theBadge,
    theBadgeModels,
    theBadgeUsers,
    theBadgeStore,
    theBadgeUsersStore,
    tpBadgeModelController,
    tpBadgeModelControllerStore,
    klerosBadgeModelController,
    klerosBadgeModelControllerStore,
  }: {
    theBadge: Contract;
    theBadgeModels: Contract;
    theBadgeUsers: Contract;
    theBadgeStore: Contract;
    theBadgeUsersStore: Contract;
    tpBadgeModelController: Contract;
    tpBadgeModelControllerStore: Contract;
    klerosBadgeModelController: Contract;
    klerosBadgeModelControllerStore: Contract;
  },
) => {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();
  const chainId = network.config.chainId;
  // The admin that is allowed to upgrade the contracts
  const contractsAdmin = deployer.address;
  const relayerAddress = process.env.RELAYER_ADDRESS || contractsAdmin;

  console.log("Grant userManager role to TheBadgeModels on TheBadgeUsers...");
  const managerRole = keccak256(utils.toUtf8Bytes("USER_MANAGER_ROLE"));
  await (await theBadgeUsers.grantRole(managerRole, theBadgeModels.address)).wait();

  console.log("Allowing TheBadge to access TheBadgeStore...");
  await (await theBadgeStore.addPermittedContract("TheBadge", theBadge.address)).wait();
  console.log("Allowing TheBadgeModels to access TheBadgeStore...");
  await (await theBadgeStore.addPermittedContract("TheBadgeModels", theBadgeModels.address)).wait();
  console.log("Allowing TheBadgeUsers to access TheBadgeStore...");
  await (await theBadgeStore.addPermittedContract("TheBadgeUsers", theBadgeUsers.address)).wait();

  console.log("Allowing TheBadgeUsers to access TheBadgeUsersStore...");
  await (await theBadgeUsersStore.addPermittedContract("TheBadgeUsers", theBadgeUsers.address)).wait();

  console.log(`Grant claimer role to the relayer address: ${relayerAddress} on ThirdPartyModelControllerStore...`);
  const claimerRole = keccak256(utils.toUtf8Bytes("CLAIMER_ROLE"));
  await (await tpBadgeModelController.grantRole(claimerRole, relayerAddress)).wait();

  console.log("Allowing ThirdPartyModelController to access TpBadgeModelControllerSTore...");
  await (
    await tpBadgeModelControllerStore.addPermittedContract("TpBadgeModelController", tpBadgeModelController.address)
  ).wait();

  console.log("Adding ThirdPartyModelController to TheBadge...");
  theBadgeModels.connect(deployer);
  await (await theBadgeModels.addBadgeModelController("thirdParty", tpBadgeModelController.address)).wait();

  if (chainId !== Chains.polygon && chainId !== Chains.mumbai) {
    console.log("Adding KlerosBadgeModelController to TheBadge...");
    theBadgeModels.connect(deployer);
    await (await theBadgeModels.addBadgeModelController("kleros", klerosBadgeModelController.address)).wait();

    console.log("Allowing KlerosBadgeModelController to access KlerosBadgeModelControllerStore...");
    await (
      await klerosBadgeModelControllerStore.addPermittedContract(
        "KlerosBadgeModelController",
        klerosBadgeModelController.address,
      )
    ).wait();
  }
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
): Promise<{
  controllersAddresses: string[][];
  klerosBadgeModelController: any;
  klerosBadgeModelControllerStore: any;
  tpBadgeModelControllerStore: any;
  tpBadgeModelController: any;
}> => {
  const { klerosControllers, klerosBadgeModelController, klerosBadgeModelControllerStore } =
    await deployKlerosControllers(hre, { theBadge, theBadgeModels });

  const { tpBadgeModelControllerStore, tpControllers, tpBadgeModelController } = await deployThirdPartyControllers(
    hre,
    { theBadge, theBadgeModels, theBadgeUsers },
  );

  return {
    controllersAddresses: [...klerosControllers, ...tpControllers],
    klerosBadgeModelController,
    klerosBadgeModelControllerStore,
    tpBadgeModelController,
    tpBadgeModelControllerStore,
  };
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
