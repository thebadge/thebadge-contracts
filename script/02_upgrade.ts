import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  const theBadgeDeployedAddress = "0xEe4683dC9D8A61938877Ac1aC3321138C9F4153A";
  const klerosBadgeModelControllerDeployedAddress = "0x17e06B644B901630ee12dd9fdC8e4f8FDc913635";
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
