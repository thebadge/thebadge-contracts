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
      //gasPrice: 5000000000,
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
      //gasPrice: 5000000000,
    },
    polygon: {
      url: process.env.POLYGON_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 137,
      // gasPrice: 2132662188670,
    },
    mumbai: {
      url: process.env.MUMBAI_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 80001,
    },
    snowtrace: {
      url: process.env.AVAX_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 43114,
    },
    optimism: {
      url: process.env.OPTIMISM_URL || "",
      accounts: accounts,
      timeout: 100000000,
      chainId: 10,
    },
  },
  etherscan: {
    customChains: [
      {
        network: "gnosis",
        chainId: 100,
        urls: {
          apiURL: "https://api.gnosisscan.io/api",
          browserURL: "https://gnosisscan.io/",
        },
      },
      {
        network: "snowtrace",
        chainId: 43114,
        urls: {
          apiURL: "https://api.routescan.io/v2/network/mainnet/evm/43114/etherscan",
          browserURL: "https://avalanche.routescan.io",
        },
      },
    ],
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: {
      goerli: process.env.ETHERSCAN_API_KEY || "",
      sepolia: process.env.ETHERSCAN_API_KEY || "",
      gnosis: process.env.GNOSISSCAN_API_KEY || "",
      polygon: process.env.ETHERSCAN_POLYGON_API_KEY || "",
      polygonMumbai: process.env.ETHERSCAN_POLYGON_API_KEY || "",
      optimisticEthereum: process.env.ETHERSCAN_OPTIMISM_API_KEY || "",
      snowtrace: "snowtrace", // apiKey is not required, just set a placeholder
    },
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT || "",
    username: process.env.TENDERLY_USERNAME || "",
    privateVerification: false,
  },
};

export default config;
