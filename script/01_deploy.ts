import * as dotenv from "dotenv";
import hre, { upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Chains, contracts, isSupportedNetwork } from "./contracts";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers, network } = hre;
  const [deployer] = await ethers.getSigners();

  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }
  const lightGTCRFactory = contracts.LightGTCRFactory.address[chainId as Chains];
  const klerosArbitror = contracts.KlerosArbitror.address[chainId as Chains];

  // https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
  // https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading-a-contract-via-plugins
  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");

  console.log("Deploying TheBadge...");
  const theBadge = await upgrades.deployProxy(TheBadge, [deployer.address, deployer.address, deployer.address]);
  await theBadge.deployed();
  console.log(`TheBadge deployed with address: ${theBadge.address}`);

  console.log("Deploying KlerosBadgeModelController...");
  // The admin that is allowed to upgrade the contracts
  const admin = deployer.address;
  const klerosBadgeModelController = await upgrades.deployProxy(KlerosBadgeModelController, [
    admin,
    theBadge.address,
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await klerosBadgeModelController.deployed();
  console.log(`KlerosBadgeModelController deployed with address: ${klerosBadgeModelController.address}`);

  console.log("Adding KlerosBadgeModelController to TheBadge...");
  theBadge.connect(deployer);
  await theBadge.addBadgeModelController("kleros", klerosBadgeModelController.address);

  console.log("///////// Deployment finished /////////");
  console.log("TheBadge:", theBadge.address);
  console.log("klerosBadgeModelController:", klerosBadgeModelController.address);
  console.log("///////// Deployment finished /////////");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
