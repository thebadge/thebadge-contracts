<p align="center">
  <a href="https://thebadge.xyz">
    <img alt="TheBadge" src="https://thebadge.xyz/favicon.ico" width="128">
  </a>
</p>

<h1 align="center">TheBadge DApp Smart-contracts</h1>

<p align="center">
  <a href="https://discord.com/invite/FTxtkgbAC4"><img src="https://img.shields.io/discord/1006480637512917033?style=plastic" alt="Join to Discord"></a>
  <a href="https://twitter.com/intent/user?screen_name=thebadgexyz"><img src="https://img.shields.io/twitter/follow/thebadgexyz?style=social" alt="Follow us on Twitter"></a>
</p>

For questions or request information reach out via [Discord](https://discord.gg/tVP75NqVuC).

# TheBadge Contracts

## Usage

### Install requirements with yarn:

```bash
yarn
```

2. Pre-fund the executor account derived from the mnemonic with some Native Token to cover the deployment of an ERC4337 module and the pre-fund of the Safe for the test operation.

### Deployments

A collection of the different contract deployments and their addresses can be found in the [TheBadge deployments](./deployments.md) file.

## Deploy with foundry

### Prerequisites

#### Set .env file:

```
WALLET_PRIVATE_KEY=
GOERLI_URL=https://goerli.infura.io/v3/
SEPOLIA_URL=https://sepolia.infura.io/v3/
GNOSIS_URL=https://rpc.gnosischain.com/
ETHERSCAN_API_KEY=
ALCHEMY_ENDPOINT_URL=https://eth-goerli.alchemyapi.io/v2/<apiKey>
TENDERLY_PROJECT=""
TENDERLY_USERNAME=""
REPORT_GAS=true
```

#### Install Rust & Cargo

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

#### Install [foundry](https://github.com/foundry-rs/foundry/tree/master) dev toolkit:

```
1) curl -L https://foundry.paradigm.xyz/ | bash
2) bash foundryup
3) foundryup --branch master
```

#### Install submodule dependencies:

```
forge install --no-commit
```

For troubleshooting check the [fountry installation](https://book.getfoundry.sh/getting-started/installation) official guide.

### Deploy

```
yarn deploy:goerli
```

### Upgrade

```
yarn upgrade:goerli
```

### Verify contract

This command will use the deployment artifacts to compile the contracts and compare them to the onchain code.
It will also verify the contracts on tenderly.

```
yarn verify:goerli
```

### Testing

To run the tests:

```bash
yarn build
yarn test
```

## Deployments

- Please check the list of our deployed contracts [here](./deployments.md)

## Documentation

- You can check our badges architecture [here](./ERC1155-721%20Architecture.md)

- If you want to learn more give a look to our [docs](https://docs.thebadge.xyz/)

## Security and Liability

All contracts are WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## License

All smart contracts are released under BSL 1.1 - see the [LICENSE.md](LICENSE) file for details.
