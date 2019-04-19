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

This is a SmartContract Deploying environment based on "CodeXpert Tron (TRX) DApp Tutorial Template".

`tronbox.js` contains settings to deploy the SmartContract on Tron Blockchain. Checkout the documentation of TronBox to see different available options.

`contracts` directory contains source code of SmartContracts in Solidity.

`test` diractory contains scripts to check the SmartContract functions.

`build\contracts` directory compilated SmartContract files by TronBox.


------------------------

## Testing

This section is under development

------------------------
