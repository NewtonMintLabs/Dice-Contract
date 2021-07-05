var TokenMock = artifacts.require("./TokenMock.sol");
var DiceContract = artifacts.require("./DiceContract.sol");

module.exports = function (deployer) {
  deployer.deploy(TokenMock);
  deployer.deploy(DiceContract);
};
