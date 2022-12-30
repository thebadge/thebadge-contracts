import * as dotenv from "dotenv";

import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-ethers";
import "hardhat-deploy";
import "@typechain/hardhat";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";

// import "./tasks/createCollection";

dotenv.config();

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

let accounts: any[] = [];
if (process.env.PRIVATE_KEY !== undefined) {
  accounts = [process.env.PRIVATE_KEY];
} else {
  throw new Error(`PRIVATE_KEY not set`);
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
    },
    gnosis: {
      url: process.env.GNOSIS_URL || "",
      accounts: accounts,
    },
  },
  namedAccounts: {
    deployer: { default: 0 },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: process.env.YOUR_ETHERSCAN_API_KEY,
  },
};

export default config;
