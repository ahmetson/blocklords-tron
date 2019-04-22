## Blocklords (https://blocklords.io) SmartContract on Tron Blockchain.

------------------------

## Instructions :

1. Install TronLink chrome extension in browser.
2. Install TronBox for Node.js. It needs to compile and deploy SmartContract.
```
$ npm install -g tronbox
```
3. (OPTIONAL) Install tronweb for Node.js. It needs to test the SmartContract.
```
$ npm install -g tronweb
```
4. Add Private key to tronbox.js from shasta test network account of TronLink.
5. Compile and Deploy the SmartContract
```
$ tronbox compile --compile-all
$ tronbox migrate --reset --network shasta
```

--------------------------

## Structure of Project

This is a SmartContract Deploying environment based on [CodeXpert Tron (TRX) DApp Tutorial Template](https://github.com/ThisIsCodeXpert/CodeXpert-Tron-DApp-Template).

`tronbox.js` script – settings to deploy the SmartContract on Tron Blockchain. Checkout the [documentation of TronBox](https://developers.tron.network/docs/tron-box-user-guide#section-basic-commands) to see different available options.

`contracts` directory – source codes of SmartContracts in Solidity Programming Langauge.

`test` directory – scripts to check the SmartContract functions *(Need to develop this section, it should be empty for now).*

`build\contracts` directory – Smartcontract Files from output of TronBox compilation.


------------------------

##Testing:

This section is under development
------------------------
