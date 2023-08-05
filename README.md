# TheBadge - subgraph

![the_badge.png](assets%2Fimages%2Fthe_badge.png)

[![contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat)](https://github.com/thebadge/thebadge-relayer/issues)
[![MIT licensed](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/thebadge/thebadge-relayer/blob/main/LICENSE)

# Setup

This document describes how to setup your local working environment in order to contribute to the project

## Prerequisites

- [Node & npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm)
- [Yarn](https://yarnpkg.com/getting-started/install)
- Some development experience
- Technical knowledge of blockchains (especially evm)
- Knowledge of Solidity
- Knowledge of forge-js
- [Hardhat](https://hardhat.org/getting-started/)
- Knowledge of [The Graph](https://thegraph.com/docs/) (our beginner [RESOURCES.md](./RESOURCES.md) file will be a good starting place)
- You will have to have a ETH wallet with some ETH in it (for gas fees) , as weel as Gnosis Safe wallet with some ETH in it (for gas fees), finally a Goerli testnet wallet with some ETH in it (for gas fees).
- You will need to have a [Alchemy](https://www.alchemy.com/) account and a [Gnosis](https://gnosis.io/) account.
- Knowleadge about [Kleros protocol]() can be useful. [Kleros](https://kleros.io/) is a decentralized justice protocol built on Ethereum. It provides fast, secure and affordable arbitration for virtually everything.
- To know about [TheBadge](https://www.thebadge.xyz/) project, please read the [whitepaper](https://thebadge.finance/whitepaper.pdf) and the [documentation](https://docs.thebadge.xyz/thebadge-documentation/).

## Installation

1. Clone the repo
2. Install dependencies with yarn `yarn install`
3. Install submodules as well as using `yarn install`
4. Create a .env file in the root of the project and add the following variables:

```
PRIVATE_KEY=<Private wallet key>
GOERLI_URL=https://eth-goerli.g.alchemy.com/v2/<key>
GNOSIS_URL=https://rpc.gnosischain.com/
YOUR_ETHERSCAN_API_KEY=""
```

5. check file hardhat.config.js and update the networks section with your own settings
6. run `npx hardhat compile` to compile the contracts, you can as well `run compile`

## Deploying

1. run `yarn deploy:goerl` to deploy the contracts on goerli testnet
2. run `yarn deploy:gnosi` to deploy the contracts on gnosis

## Testing

1. run `yarn test` to run the tests

## Want to learn more?

You can learn more reading [docs](docs)
