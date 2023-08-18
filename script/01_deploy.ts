import * as dotenv from "dotenv";
import hre, { upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

// Todo refactor to something more fancy
const {
  GOERLI_LIGHT_GTCR_FACTORY_CONTRACT_ADDRESS,
  GOERLI_KLEROS_ARBITROR_CONTRACT_ADDRESS,
  SEPOLIA_LIGHT_GTCR_FACTORY_CONTRACT_ADDRESS,
  SEPOLIA_KLEROS_ARBITROR_CONTRACT_ADDRESS,
} = process.env;
if (
  !GOERLI_LIGHT_GTCR_FACTORY_CONTRACT_ADDRESS ||
  !GOERLI_KLEROS_ARBITROR_CONTRACT_ADDRESS ||
  !SEPOLIA_LIGHT_GTCR_FACTORY_CONTRACT_ADDRESS ||
  !SEPOLIA_KLEROS_ARBITROR_CONTRACT_ADDRESS
) {
  throw new Error(`Contract addresses not set!`);
}

const lightGTCRFactory = SEPOLIA_LIGHT_GTCR_FACTORY_CONTRACT_ADDRESS;
const klerosArbitror = SEPOLIA_KLEROS_ARBITROR_CONTRACT_ADDRESS;

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
