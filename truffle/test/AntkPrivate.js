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
  const other = accounts[9];
  const arrayWhitelist = [owner, whitelist1, whitelist2, whitelist3, whitelist4, whitelist5, whitelist6];

  let AntkPrivateInstance;
  let USDTinstance;

  // ::::::::::::: setWhitelist ::::::::::::: //

  describe("test of setWhitelist", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })

    })

    it("...should return isWhitelisted false", async () => {
      const investor = await AntkPrivateInstance.investors.call(buyer4)
      expect(investor[0]).to.be.false
    })

    it("...should set a isWhitelisted buyer at true, return true", async () => {
      await AntkPrivateInstance.setWhitelist(arrayWhitelist, { from: owner })
      for (i = 0; i < 7; i++) {
        const investor = await AntkPrivateInstance.investors.call(arrayWhitelist[i])
        expect(investor[0]).to.be.true
      }
    })

    it("...should revert because of Ownable", async () => {
      await expectRevert(AntkPrivateInstance.setWhitelist([buyer5, other], { from: buyer5 }), "Ownable: caller is not the owner");
    });

  })

  // ::::::::::::: changeSalesStatus ::::::::::::: //

  describe("test of changeSalesStatus", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
    })

    it("...should revert because of Ownable", async () => {
      await expectRevert(AntkPrivateInstance.changeSalesStatus(2, { from: other }), "Ownable: caller is not the owner");
    })

    it("...should return salesStatus = 0", async () => {
      const currentStatus = await AntkPrivateInstance.salesStatus()
      expect(BN(currentStatus)).to.be.bignumber.equal(BN(0))
    })

    it("...should return salesStatus = 1", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      const currentStatus = await AntkPrivateInstance.salesStatus()
      expect(BN(currentStatus)).to.be.bignumber.equal(BN(1))
    })

    it("...should emit newStatus", async () => {
      const event = await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      expectEvent(event, "newStatus", { newStatus: BN(2) })
    })

  })

  // ::::::::::::: calculNumberOfTokenToBuy ::::::::::::: //

  describe("test of calculNumberOfTokenToBuy", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
    })

    it("...should return 100 000 000", async () => {
      const number = await AntkPrivateInstance.calculNumberOfTokenToBuy(60000)
      expect(BN(number)).to.be.bignumber.equal(BN(100000000))
    })

    it("...should return 150 000 000", async () => {
      const number = await AntkPrivateInstance.calculNumberOfTokenToBuy(100000)
      expect(BN(number)).to.be.bignumber.equal(BN(150000000))
    })

    it("...should revert because amount > 100 000", async () => {
      await expectRevert(AntkPrivateInstance.calculNumberOfTokenToBuy(150000, { from: other }), "Vous ne pouvez pas investir plus de 100 000 $");
    })

  })

  // ::::::::::::: buyTokenWithTether ::::::::::::: //

  describe("test of buyTokenWithTether", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
    })

    it("...should revert because of Status", async () => {
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of not whitelisted", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of amount", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(10, { from: other }), "Ce montant est inferieur au montant minimum !");
    })

  })

})