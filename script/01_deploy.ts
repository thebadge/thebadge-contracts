import * as dotenv from "dotenv";
import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();

  // https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
  // https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading-a-contract-via-plugins

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosBadgeModelController");

  // GBC:
  // const lightGTCRFactory = "0x08e58Bc26CFB0d346bABD253A1799866F269805a";
  // const klerosArbitror = "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002";

  // Goerli
  const lightGTCRFactory = "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314";
  const klerosArbitror = "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a";

  console.log("Deploying TheBadge...");
  const theBadge = await upgrades.deployProxy(TheBadge, [deployer.address, deployer.address, deployer.address]);
  await theBadge.deployed();

  console.log("Deploying KlerosBadgeModelController...");
  const klerosController = await upgrades.deployProxy(KlerosController, [
    theBadge.address,
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await klerosController.deployed();

  console.log("Adding KlerosBadgeModelController...");
  theBadge.connect(deployer);
  await theBadge.setBadgeModelController("kleros", klerosController.address);

  console.log("TheBadge:", theBadge.address);
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
