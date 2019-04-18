module.exports = {
  networks: {
//    development: {
// For trontools/quickstart docker image
    //   privateKey: '6eaa53a6d911fbb1e3e5515eb6ad222053e7e1ba2e6973f0e91ff2d20161ed6d',
    //   consume_user_resource_percent: 30,
    //   fee_limit: 100000000,
    //   fullNode: "http://127.0.0.1:8090",
    //   solidityNode: "http://127.0.0.1:8091",
    //   eventServer: "http://127.0.0.1:8092",
    //   network_id: "*"
    // },
    shasta: {
      privateKey: 'ec9e4c10724b406709d609c61a2f151cc4f8ab6950e45a70347f4b4aad3e02e5',
      consume_user_resource_percent: 30,
      fee_limit: 900000000,
      fullNode: "https://api.shasta.trongrid.io",
      solidityNode: "https://api.shasta.trongrid.io",
      eventServer: "https://api.shasta.trongrid.io",
      network_id: "*"
    },
    mainnet: {
// Don't put your private key here, pass it using an env variable, like:
// PK=da146374a75310b9666e834ee4ad0866d6f4035967bfc76217c5a495fff9f0d0 tronbox migrate --network mainnet
      privateKey: "",
      consume_user_resource_percent: 30,
      fee_limit: 900000000,
      fullNode: "https://api.trongrid.io",
      solidityNode: "https://api.trongrid.io",
      eventServer: "https://api.trongrid.io",
      network_id: "*"
    }
  }
};
