import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import * as dotenv from "dotenv";

dotenv.config();
// Todo refactor to something more fancy
const {
  GOERLI_THE_BADGE_CONTRACT_ADDRESS,
  GOERLI_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS,
  SEPOLIA_THE_BADGE_CONTRACT_ADDRESS,
  SEPOLIA_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS,
} = process.env;
if (
  !GOERLI_THE_BADGE_CONTRACT_ADDRESS ||
  !GOERLI_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS ||
  !SEPOLIA_THE_BADGE_CONTRACT_ADDRESS ||
  !SEPOLIA_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS
) {
  throw new Error(`Contract addresses not set!`);
}
const theBadgeDeployedAddress = SEPOLIA_THE_BADGE_CONTRACT_ADDRESS;
const klerosBadgeModelControllerDeployedAddress = SEPOLIA_KLEROS_BADGE_MODEL_CONTROLLER_CONTRACT_ADDRESS;

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;

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
