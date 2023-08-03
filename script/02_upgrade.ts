import * as dotenv from "dotenv";
import hre, { upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;

  // const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  // console.log("Deploying TheBadge...");
  // const theBadge = await upgrades.upgradeProxy("0x059a97A4ad4D148B39209Fa9Be262E6E00E97804", TheBadge);
  // await theBadge.deployed();

  console.log("Upgrading KlerosBadgeModelController...");
  const klerosController = await upgrades.upgradeProxy("0x21bDD74A233339Ee96e6f208b118f29FbF27BdEA", KlerosController);
  await klerosController.deployed();

  // console.log("TheBadge:", theBadge.address);
  console.log("klerosBadgeTypeController:", klerosController.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
