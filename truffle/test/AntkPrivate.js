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

      USDTinstance = await USDT.new({ from: buyer4 })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
    })

    it("...should revert because of Status", async () => {
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of not whitelisted", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of not approve", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: buyer4 }), "Vous n'avez pas approuve le transfert de Tether !");
    })

    it("...should revert because of not enough USDT", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 50000000000, { from: buyer5 })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, { from: buyer5 }), "Vous n'avez pas assez de Tether !");
    })

    it("...should revert because of minimum amout to buy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 50000000000, { from: buyer4 })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(0.1, { from: buyer4 }), "underflow");
    })

    it("...should emit Tokensbuy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      const event = await AntkPrivateInstance.buyTokenWithTether(60000, { from: buyer4 });
      expectEvent(event, "TokensBuy", { addressBuyer: buyer4, numberOfTokensPurchased: BN(100000000), amountSpendInDollars: BN(60000) })
    })

    it("...should return USDT balance of 30 000x10**6 ", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, { from: buyer4 });
      const tokensBuy = await USDTinstance.balanceOf(AntkPrivateInstance.address)
      expect(BN(tokensBuy)).to.be.bignumber.equal(BN(30000000000))
    })

    it("...should revert because not enough token to buy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.transfer(whitelist1, 100000000000, { from: buyer4 })
      await USDTinstance.transfer(whitelist2, 100000000000, { from: buyer4 })
      await USDTinstance.transfer(whitelist3, 100000000000, { from: buyer4 })
      await USDTinstance.transfer(whitelist4, 100000000000, { from: buyer4 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: buyer4 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist1 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist2 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist3 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist4 })
      await AntkPrivateInstance.buyTokenWithTether(100000, { from: buyer4 });
      await AntkPrivateInstance.buyTokenWithTether(100000, { from: whitelist1 });
      await AntkPrivateInstance.buyTokenWithTether(100000, { from: whitelist2 });
      await AntkPrivateInstance.buyTokenWithTether(100000, { from: whitelist3 });
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(100000, { from: whitelist4 }), "Il ne reste plus assez de tokens disponibles !")
    })

  })

  // ::::::::::::: buyTokenWithEth ::::::::::::: //

  describe("test of buyTokenWithEth", async () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: buyer4 })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
    })

    it("...should revert because of status", async () => {
      await expectRevert(AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 }), "Vous ne pouvez pas investir pour le moment !")
    })

    it("...should revert because of status", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 }), "Vous ne pouvez pas investir pour le moment !")
    })

    it("...should return 7500", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors.call(buyer5)
      expect(BN(investor[2])).to.be.bignumber.equal(BN(7500))
    })

    it("...should return ETH", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors.call(buyer5)
      expect(investor[3]).to.equal("ETH")
    })

    it("...should return 12 500 000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors.call(buyer5)
      expect(BN(investor[1])).to.be.bignumber.equal(BN(12500000))
    })

    it("...should emit TokensBuy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      const event = await AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 })
      expectEvent(event, "TokensBuy", { addressBuyer: buyer5, numberOfTokensPurchased: BN(12500000), amountSpendInDollars: BN(7500) })
    })

    it("...should return balance of ETH", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth({ from: buyer5, value: 5000000000000000000 })
      const funds = await AntkPrivateInstance.seeFunds()
      expect(funds[1].toString()).to.be.equal('5000000000000000000')
    })


  })

  // ::::::::::::: getFunds ::::::::::::: //

  describe("test of getFunds", async () => {
    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: buyer4 })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })
      await USDTinstance.transfer(whitelist1, 100000000000, { from: buyer4 })
      await USDTinstance.transfer(whitelist2, 100000000000, { from: buyer4 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist1 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist2 })
      await AntkPrivateInstance.setWhitelist(arrayWhitelist, {from : owner})
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await AntkPrivateInstance.buyTokenWithTether(100000, { from: whitelist1 })
      await AntkPrivateInstance.buyTokenWithTether(80000, { from: whitelist2 })
    })

    it("...should return balance owner USDT 180 000", async () => {
      await AntkPrivateInstance.getFunds({ from : owner })
      const balanceUsdt = await USDTinstance.balanceOf(owner)
      expect(BN(balanceUsdt)).to.be.bignumber.equal(BN(180000000000))
    })

    
  })

})