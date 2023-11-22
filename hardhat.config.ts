import * as dotenv from "dotenv";

import * as tenderly from "@tenderly/hardhat-tenderly";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@openzeppelin/hardhat-upgrades";

dotenv.config();
tenderly.setup({ automaticVerifications: false });

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
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
          viaIR: true,
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
    gnosis: {
      url: process.env.GNOSIS_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 100,
    },
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
  tenderly: {
    project: process.env.TENDERLY_PROJECT || "",
    username: process.env.TENDERLY_USERNAME || "",
    privateVerification: false,
  },
};

export default config;
