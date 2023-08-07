import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  // console.log("Deploying TheBadge...");
  // const theBadge = await upgrades.upgradeProxy("0x059a97A4ad4D148B39209Fa9Be262E6E00E97804", TheBadge);
  const theBadge = await upgrades.upgradeProxy("0x5E7c648EE852241f145e1d480932C091979883D1", TheBadge);
  await theBadge.deployed();

  console.log("Upgrading KlerosBadgeModelController...");
  const klerosController = await upgrades.upgradeProxy("0x17174F4B1DCd25183Bf53E675ee5AF37e2baa37a", KlerosController);
  await klerosController.deployed();

  // console.log("TheBadge:", theBadge.address);
  console.log("klerosBadgeModelController:", klerosController.address);

  console.log("Verifying TheBadge contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadge.address,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosController.address,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
