import * as dotenv from "dotenv";

import * as tdly from "@tenderly/hardhat-tenderly";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();
tdly.setup();

let accounts: any[] = [];
if (process.env.WALLET_PRIVATE_KEY !== undefined) {
  accounts = [process.env.WALLET_PRIVATE_KEY];
} else {
  throw new Error(`WALLET_PRIVATE_KEY not set`);
}

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.17",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  paths: {
    artifacts: "./artifacts",
    sources: "./src",
  },
  networks: {
    goerli: {
      url: process.env.GOERLI_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 5,
      gasPrice: 5000000000,
    },
    sepolia: {
      url: process.env.SEPOLIA_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 11155111,
      // gasPrice: 5000000000,
    },
    // gnosis: {
    //   url: process.env.GNOSIS_URL || "",
    //   accounts: accounts,
    // },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      gnosis: process.env.ETHERSCAN_API_KEY || "",
    },
  },
};

export default config;
