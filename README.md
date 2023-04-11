# Solvest

Improved version of the [MakerDAO dss-vest contracts](https://github.com/makerdao/dss-vest/blob/master). Solvest allows to easily create multiple vesting plans with different parameters.

Most noticeable differences compared to `dss-vest`:
- Better naming
- The owner can protect/unprotect a vesting plan to be revoked by a manager.

## [MintVest](./src/MintVest.sol)

Pass the address of the vesting token to the constructor on deploy. This contract must be given authority to `mint()` tokens in the vesting contract.

## [TransferVest](./src/TransferVest.sol)

Pass the authorized sender address and the address of the token contract to the constructor to set up the contract for streaming arbitrary ERC20 tokens. Note: this contract must be given approval by the sender to spend tokens on its behalf.

## Installation

Download foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
```

Install it:
```bash
foundryup
```

Install dependencies:
```bash
git submodule update --init --recursive
```

Now you can run tests, using forge:
```bash
forge test
```
