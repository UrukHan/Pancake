## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

## Deploy
```shell
forge script script/DeployOptimizedSwapAndLiquidity.s.sol --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545/ --private-key ... --broadcast --verify --etherscan-api-key ... -vvvv
```

## Add RPC URL to envirement
```shell
export BSC_RPC_URL=https://bsc-dataseed.binance.org/
```

### RUN TEST in BSC fork

```shell
forge test --fork-url $BSC_RPC_URL -vvv
```


### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
