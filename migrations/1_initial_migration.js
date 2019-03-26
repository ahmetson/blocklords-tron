var Migrations = artifacts.require("./Blocklords.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
};
