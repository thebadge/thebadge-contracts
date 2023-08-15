import * as dotenv from "dotenv";
import hre, { run, upgrades } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const theBadgeDeployedAddress = "0xeCc0B0B2715bc6b6a0E42Eb9A7139aE28A360045";
  const klerosBadgeModelControllerDeployedAddress = "0x84a93d11E9973826095ED7D0a0388949Eed38d63";

  console.log("Verifying TheBadge contract on Etherscan...");
  await run(`verify:verify`, {
    address: theBadgeDeployedAddress,
    constructorArguments: [],
  });

  console.log("Verifying KlerosBadgeModelController contract on Etherscan...");
  await run(`verify:verify`, {
    address: klerosBadgeModelControllerDeployedAddress,
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
