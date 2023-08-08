import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  // console.log("Deploying TheBadge...");
  const theBadgeDeployedAddress = "0xFe5fBC9374fc1BB7395A4012d1bc0dE34E8F60Df";
  const klerosBadgeModelControllerDeployedAddress = "0x87249C14deD941CE64f1955Db264ee1440AE5fb5";
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

  console.log("Verifying TheBadge contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadge.address,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosBadgeModelController.address,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
