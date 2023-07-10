# AA Sample

The project implements ERC-4337, Account Abstraction, allowing users to transfer and manage funds as a wallet, while also enabling the payment of transaction fees using ERC-20 tokens.

## Features

- Transfer ether and tokens conforming to ERC-20, ERC-721, and ERC-1155 standards as normal wallet
- Perform multiple transactions in one single on-chain transaction, aka batch transaction
- Pay the transaction fee using ERC-20 tokens, `TestToken`, instead of ether
- Custom modules, e.g. `SpendLimit` for preventing spending more tokens than the limit set by the account's owner

## How to build

The project is built with [foundry](https://github.com/foundry-rs/foundry). Install it if you haven't.

```
curl -L https://foundry.paradigm.xyz | bash
```

Run the following command to clone the repo and build

```bash
git clone git@github.com:Doge-is-Dope/aa-sample.git
cd aa-sample
forge install
forge build
```

## Testing

To run the tests, simply run the following command.

```bash
forge test
```
