const USDT = artifacts.require("USDT");
const AntkPrivateTest = artifacts.require("AntkPrivateTest");

module.exports = function (deployer) {

  // deployer.deploy(USDT);
  
  deployer.deploy(AntkPrivateTest, '0xaf808444D88d83ceCA6aDfa103472b3F23601a7e');
};
//  console.log(USDT.network.address);