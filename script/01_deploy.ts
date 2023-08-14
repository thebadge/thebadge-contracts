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
  const KlerosBadgeModelController = await ethers.getContractFactory("KlerosBadgeModelController");

  // GBC:
  // const lightGTCRFactory = "0x08e58Bc26CFB0d346bABD253A1799866F269805a";
  // const klerosArbitror = "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002";

  // Goerli
  const lightGTCRFactory = "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314";
  const klerosArbitror = "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a";

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
