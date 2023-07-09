import * as dotenv from "dotenv";
import hre, { upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();

  // https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
  // https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading-a-contract-via-plugins

  const TheBadge = await ethers.getContractFactory("TheBadge");
  const KlerosController = await ethers.getContractFactory("KlerosController");

  // GBC:
  // const lightGTCRFactory = "0x08e58Bc26CFB0d346bABD253A1799866F269805a";
  // const klerosArbitror = "0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002";

  // Goerli
  const lightGTCRFactory = "0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314";
  const klerosArbitror = "0x1128ed55ab2d796fa92d2f8e1f336d745354a77a";

  console.log("Deploying TheBadge...");
  const theBadge = await upgrades.deployProxy(TheBadge, [deployer.address, deployer.address, deployer.address]);
  await theBadge.deployed();

  console.log("Deploying KlerosBadgeTypeController...");
  const klerosController = await upgrades.deployProxy(KlerosController, [
    theBadge.address,
    klerosArbitror,
    lightGTCRFactory,
  ]);
  await klerosController.deployed();

  console.log("Assign Kleros Controller...");
  theBadge.connect(deployer);
  await theBadge.setBadgeModelController("kleros", klerosController.address);

  // TODO: set kleros controller

  console.log("TheBadge:", theBadge.address);
  console.log("klerosBadgeTypeController:", klerosController.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// TheBadge: 0x856a42E48b6e5044F409af58bca209aE1BBF3c34
// klerosBadgeTypeController: 0x3aF4A7dE2303fed507b1Af0A1652dCb22F0D7D8e
