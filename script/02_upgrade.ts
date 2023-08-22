import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import * as dotenv from "dotenv";
import { Chains, contracts, isSupportedNetwork } from "./contracts";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers, network } = hre;

  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }
  const theBadgeDeployedAddress = contracts.TheBadge.address[chainId as Chains];
  const klerosBadgeModelControllerDeployedAddress = contracts.KlerosBadgeModelController.address[chainId as Chains];

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  console.log(`Upgrading TheBadge with address: ${theBadgeDeployedAddress}...`);
  const theBadge = await upgrades.upgradeProxy(theBadgeDeployedAddress, TheBadge);
  await theBadge.deployed();

  console.log(`Upgrading KlerosBadgeModelController with address: ${klerosBadgeModelControllerDeployedAddress}...`);
  const klerosBadgeModelController = await upgrades.upgradeProxy(
    klerosBadgeModelControllerDeployedAddress,
    KlerosController,
  );
  await klerosBadgeModelController.deployed();

  console.log("///////// UPGRADE finished /////////");
  console.log("TheBadge:", theBadge.address);
  console.log("klerosBadgeModelController:", klerosBadgeModelController.address);
  console.log("///////// UPGRADE finished /////////");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
