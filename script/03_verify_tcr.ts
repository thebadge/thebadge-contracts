import * as dotenv from "dotenv";
import hre, { run, tenderly, ethers } from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { Chains, contracts, isSupportedNetwork } from "./contracts";
import { getImplementationAddress } from "@openzeppelin/upgrades-core";

dotenv.config();

const tenderlyVerifyMainContracts = async (hre: HardhatRuntimeEnvironment) => {
  const { network } = hre;
  const chainId = network.config.chainId;

  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  const lightGTCRFactory = contracts.CustomLightGTCRFactory.address[chainId as Chains];
  const lightGTCR = contracts.CustomLightGTCR.address[chainId as Chains];

  // Verify on tenderly
  console.log("Verifying main contracts on Tenderly...");
  const deployedContracts = [
    {
      name: "LightGTCRFactory",
      address: lightGTCRFactory,
      network: chainId.toString(),
    },
    {
      name: "LightGeneralizedTCR",
      address: lightGTCR,
      network: chainId.toString(),
    },
  ];
  await tenderly.verify(...deployedContracts);
};

const verifyMainContracts = async (hre: HardhatRuntimeEnvironment) => {
  const { network } = hre;
  const chainId = network.config.chainId;

  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  const lightGTCRFactory = contracts.CustomLightGTCRFactory.address[chainId as Chains];
  const lightGTCR = contracts.CustomLightGTCR.address[chainId as Chains];

  console.log("Verifying LightGTCR contract on Etherscan...");
  await run(`verify:verify`, {
    address: lightGTCR,
    constructorArguments: [],
  });

  console.log("Verifying LightGTCRFactory contract on Etherscan...");
  await run(`verify:verify`, {
    address: lightGTCRFactory,
    constructorArguments: [lightGTCR],
  });

  await tenderlyVerifyMainContracts(hre);
};

async function main() {
  const { network } = hre;
  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  console.log("Verifying main contracts...");
  await verifyMainContracts(hre);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
