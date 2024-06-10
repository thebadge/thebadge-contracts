import * as dotenv from "dotenv";
import hre from "hardhat";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { isSupportedNetwork } from "./contracts";

dotenv.config();

async function main(hre: HardhatRuntimeEnvironment) {
  const { network } = hre;

  const chainId = network.config.chainId;
  if (!chainId || !isSupportedNetwork(chainId)) {
    throw new Error(`Network: ${chainId} is not defined or is not supported`);
  }

  // https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent_proxy
  // https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading-a-contract-via-plugins

  console.log("Deploying Main contracts...");
  const { mainContracts } = await deployMainContracts(hre);

  console.log("///////// Deployment finished /////////");
  for (const mainContractsAddresses of mainContracts) {
    console.log(`${mainContractsAddresses[0]}: ${mainContractsAddresses[1]}`);
  }
  console.log("///////// Deployment finished /////////");
}

const deployMainContracts = async (
  hre: HardhatRuntimeEnvironment,
): Promise<{
  mainContracts: string[][];
}> => {
  const { ethers } = hre;
  const [deployer] = await ethers.getSigners();
  const deployedAddresses = [];

  const LGTCR = await ethers.getContractFactory("LightGeneralizedTCR", deployer);
  const LGTCRDeploy = await LGTCR.deploy();
  await LGTCRDeploy.deployed();

  console.log(LGTCRDeploy.address, "address of LGTCR");
  const LGTCRAddress = LGTCRDeploy.address;

  const LGTCRFactory = await ethers.getContractFactory("LightGTCRFactory", deployer);
  const LGTCRFactoryDeploy = await LGTCRFactory.deploy(LGTCRDeploy.address);
  await LGTCRFactoryDeploy.deployed();

  console.log(LGTCRFactoryDeploy.address, "address of LGTCR factory");
  const LGTCRFactoryAddress = LGTCRFactoryDeploy.address;
  deployedAddresses.push(["LGTCRAddress", LGTCRAddress]);
  deployedAddresses.push(["LGTCRFactoryAddress", LGTCRFactoryAddress]);

  return {
    mainContracts: deployedAddresses,
  };
};

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
