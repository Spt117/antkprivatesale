const USDT = artifacts.require("./USDT.sol");
const AntkPrivateTest = artifacts.require("./AntkPrivateTest.sol");

const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

const { expect } = require('chai');

contract('AntkPrivateTest', accounts => {

  const owner = accounts[0];
  const whitelist1 = accounts[1];
  const whitelist2 = accounts[2];
  const whitelist3 = accounts[3];
  const whitelist4 = accounts[4];
  const whitelist5 = accounts[5];
  const whitelist6 = accounts[6];
  const buyer4 = accounts[7];
  const buyer5 = accounts[8];
  const buyer6 = accounts[9];
  const arrayWhitelist = [owner, whitelist1, whitelist2, whitelist3, whitelist4, whitelist5, whitelist6];

  let AntkPrivateInstance;

  // ::::::::::::: setWhitelist ::::::::::::: //

  describe("test of setWhitelist", () => {

    beforeEach (async () => {
      AntkPrivateInstance = await AntkPrivateTest.new({from : owner})
    })

    it("...should return isWhitelisted false", async () => {
      const investor = await AntkPrivateInstance.investors.call(buyer4)
      expect(investor[0]).to.be.false
    })

    it("...should set a isWhitelisted buyer at true, return true", async () => {
      await AntkPrivateInstance.setWhitelist(arrayWhitelist, {from : owner})
      for (i=0 ; i<7 ; i++){
      const investor = await AntkPrivateInstance.investors.call(arrayWhitelist[i])
      expect(investor[0]).to.be.true
    }      console.log(arrayWhitelist)
    })

    it("...should revert because of Ownable", async () => {
      await expectRevert(AntkPrivateInstance.setWhitelist([buyer5, buyer6], {from : buyer5}),"Ownable: caller is not the owner");
  });

  })

})