# Building an Automatic Payment Protocol on Telos

In this project, we will implement a simple automatic payment protocol, which is a continuous and automated payment system implemented through smart contracts. This ensures that you no longer have to worry about being owed wages by your employer.

## Project Overview

The Automatic Payment Protocol on Telos aims to streamline the payment process by leveraging blockchain technology. By using smart contracts, payments can be scheduled and executed automatically, reducing the need for manual intervention and ensuring timely payments.

## Implementation Details

In this section, we will use Foundry to complete the creation and on-chain deployment of the project. Please make sure that Foundry and VSCode development environment have been installed. If you are not familiar with Foundry, you can quickly learn Hackquest's Foundry series of courses, or configure it according to the official documentation. Of course, if you want to use Remix, it is also OK. It will be more friendly for the deployment and calling of simple contracts.

Please note: The version of Foundry used here is forge 0.2.0, and the deployment network is Telos EVM. Due to the continuous iteration of Foundry and Telos versions, some configurations may change. Please refer to the documentation.

### Initialize the Project

Execute the following command to initialize an empty llamapay_demo project and manage the project with VSCode. The directory structure is as follows:
```sh
forge init llamapay_demo
```
![Project Structure](img)

Next, add `MyToken.sol` and `LlamaPay.sol` files to the `src` directory. The complete smart contract code is on the right 👉. In the LlamaPay contract, we have added a `getPayerBalance` function to record the balance changes of the payer (Boss).
```solidity
function getPayerBalance(address payerAddress) external view returns (int) {
    Payer storage payer = payers[payerAddress];
    int balance = int(balances[payerAddress]);
    uint delta = block.timestamp - payer.lastPayerUpdate;
    int res = (balance - int(delta * uint(payer.totalPaidPerSec))) / int(DECIMALS_DIVISOR);
    return res;
}
```
This function is mainly used to calculate and return the current balance of Boss during the streaming payment process. It calculates the total amount due since the last update and deducts it from the current balance to obtain the latest balance value, taking into account the dynamic changes in streaming payments.

Please note: the `int` type is used as the function return value here. Why is this the case? Due to the characteristics of streaming payments, the balance may become negative after deducting the payment amount. For example, when a payer does not have enough funds to pay all the due amounts, the balance may become negative. In this case, using the `int` type can accurately reflect the payer's liabilities.

### On-Chain Deployment

We can collect 50 test tokens at the Telos faucet address as follows:
![Telos Faucet](img)

Next, execute the following command to install the OpenZeppelin dependency (if there is uncommitted code in git, the forge command will fail, just commit as prompted by the error):
```sh
forge install OpenZeppelin/openzeppelin-contracts
```

To better manage the sensitive configuration information of the project, we add the private key and `TELOS_RPC` address of the configuration account in the `.env` file as follows:
![.env Configuration](img)

Open the VSCode terminal, first execute the `source` command to load the previous configuration information, then execute the `forge create` command to deploy the `MyToken` contract, and get the contract address:
```sh
source .env
forge create --rpc-url $TELOS_TEST_RPC_URL --private-key $PRIVATE_KEY src/MyToken.sol:MyToken --legacy
```
```
[⠢] Compiling...
No files changed, compilation skipped
Deployer: 0xf2D55aC64536c3E626ADDfb121c7056a7b440901
Deployed to: 0x463c8d43995eA2004873F6d083a118A6bAC6C4Cd
Transaction hash: 0x21e44823fba1a00ad07e797acce666af2693ab61b69555d2f6cfc20909e36fd9
```

Next, we deploy the `MyToken` contract address from the previous step as the construction parameter of the `LlamaPay` contract. The resulting contract address is:
```sh
forge create --rpc-url $TELOS_TEST_RPC_URL --private-key $PRIVATE_KEY src/LlamaPay.sol:LlamaPay --constructor-args 0x463c8d43995eA2004873F6d083a118A6bAC6C4Cd --legacy
```
```
[⠢] Compiling...
No files changed, compilation skipped
Deployer: 0xf2D55aC64536c3E626ADDfb121c7056a7b440901
Deployed to: 0x2C10C47e7784c64A92F226525eD9bF72D4CcdAA3
Transaction hash: 0x35489d9b08776d986fe161a34182b81586173290d70f3f54d53782dd48731db9
```

We can view the corresponding deployment results on the blockchain browser, the corresponding transaction addresses `MyToken` contract and `LlamaPay` contract.
![Deployment Results](img)

### Summary

This article describes how to create and deploy smart contracts using Foundry. We need to install Foundry and VSCode first, then initialize the project, install dependencies, configure sensitive information, and deploy the contract on the Telos testnet.
