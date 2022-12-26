import * as dotenv from "dotenv";
import hre from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

async function main(hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts, ethers } = hre;
  const { deploy } = deployments;

  const { deployer } = await ethers.getNamedSigners();

  const collection = await deploy("TheBadge", {
    from: deployer.address,
    contract: "TheBadge",
    args: [],
    log: true,
    autoMine: true,
  });

  //await collection.deployed();

  console.log("TheBadge:", collection.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
