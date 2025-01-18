# Building a Staking Protocol on Telos

This course will guide you in implementing a staking protocol on Telos.

## Overview

In this project, you will learn how to build a staking protocol on the Telos blockchain. Staking protocols allow users to lock up their tokens in a smart contract to earn rewards over time. This is a fundamental aspect of many blockchain ecosystems, providing security and stability to the network.

## Deployment and Interaction

In this section, we will use Foundry to create and deploy a project to the blockchain. Before we start, please ensure you have installed Foundry and the VSCode development environment. If you are new to Foundry, you can quickly learn from Hackquest's Foundry series courses, or refer to the official documentation for setup.

**Note:** The version of Foundry used here is forge 0.2.0, and the deployment network is Telos EVM. As Foundry and Telos evolve, some configurations might change, so please refer to the actual setup.

### Initializing the Project

Run the following command to initialize an empty MasterChef project and manage the project with VSCode. The directory structure is as follows:
```sh
forge init MasterChef
```

Next, add a `MasterChef.sol` file in the `src` directory. The complete smart contract code is on the right 👉

### On-chain Deployment

First, get some Telos EVM Testnet tokens from the Telos Faucet. Enter your wallet address and click “SEND TESTNET EVM TLOS” to receive the test tokens needed for deployment and interaction.

Next, run the following command to install the OpenZeppelin dependencies (to keep consistent with the MasterChef compilation environment, we use version 3.4.0 here. If there are uncommitted changes in git, the forge command will fail, so please commit as instructed by the error message):
```sh
forge install OpenZeppelin/openzeppelin-contracts@v3.4.0
```

To successfully deploy the contract, we also need to configure two files in the root folder, namely `remappings.txt` and `args.txt`, to point to the OpenZeppelin code library path and the constructor arguments path:

**remappings.txt**
```
@openzeppelin/=lib/openzeppelin-contracts/
```

**args.txt**
```
0x516de3a7a567d81737e3a46ec4ff9cfd1fcb0136 1000000000000000000 100
```

To better manage sensitive project configuration information, we add a `.env` file to configure the account's private key and TELOS_RPC address as follows:

Open the VSCode terminal, first run the `source` command to load the previous configuration information, and then run the `forge create` command to deploy the MasterChef contract, getting the contract address `0x019…1046`:
```sh
source .env
forge create --rpc-url $TELOS_TEST_RPC_URL --private-key $PRIVATE_KEY src/MasterChef.sol:MasterChef --constructor-args-path args.txt --legacy
```

### On-chain Interaction

Next, we will briefly demonstrate the interaction process with the contract.

#### Adding a New Liquidity Pool to the Contract

Here we use the `cast send` command to call the `add` function. To simplify the command, we use `export` to set the previously created MasterChef contract and the LPToken address used for testing as environment variables. The result is as follows:
```sh
export MasterChef=0x01944990EED21609a333dc1ED52010026e911046
export LPTokenAddress=0x516de3a7a567d81737e3a46ec4ff9cfd1fcb0136
cast send --private-key $PRIVATE_KEY $MasterChef "add(uint256,address,bool)" 1000 $LPTokenAddress true --rpc-url $TELOS_TEST_RPC_URL --gas-limit 21644000 --legacy 
```

We have performed a simple interaction with the contract. Of course, there are more interesting features to explore, such as how to deposit and withdraw, update the pool, and so on. After completing the contract deployment, please continue to try it out. You can also add more features you want to the contract, and let your imagination run wild to continuously improve it! 🚀🚀🚀
