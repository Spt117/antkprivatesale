const AntkPrivateTest = artifacts.require("./AntkPrivate.sol");
const USDT = artifacts.require("./USDT.sol");

const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract('AntkPrivateTest', accounts => {

  const owner = accounts[0]
  const whitelist1 = accounts[1];
  const whitelist2 = accounts[2];
  const whitelist3 = accounts[3];
  const whitelist4 = accounts[4];
  const whitelist5 = accounts[5];
  const whitelist6 = accounts[6];
  const buyer4 = accounts[7];
  const buyer5 = accounts[8];
  const other = accounts[9];
  // const owner = '0x1Bf9Ee786B600A294DFd0151D1aF027a286A8f4B';
  const whitelist10 = '0x39C4Ce965b9F81de90D5F91127afB807bdd1F705';
  const root = '0x7875fc36bf337bf2380d97983798535175ffea79f962cae2486a4cc26010ca08';
  const merkleProof = [0xe4506196644de3e89c3c54b222159d85ec4f190db43b8f73717d0b6d999e5b74, 0x2051b23223f6d5d83040309ebe1f9910538fd0d2137237f11cba78178cc7bd37, 0xecf69cabc20f2ae0792c63c8208a565313fea1aa62f2c2f36089554a036fce67, 0xbb266e6e62b2d273fcc37081216848aec7b90478646fafb132f58fd57271751b, 0x08b60d69d596a6ce1e54ff87bdf9e390a4319b701a25bb8abdec4e67ee248487]
  const merkleProof2 = ["0x317ad114c8852985eba29964133925507984e84cacaed9e4e7f78bcbe481b4ec", "0x51f2294c70e5acdf60c2284a831ea35f24421be98f6e762ae95ca7ef522039ae"]
  const merkleProof3 = ["0x593536617a764d87868776ad17abb710e27751f667631ad29751cbcf02a6c12d"]
  const goerliEthChainlink = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

  let AntkPrivateInstance;
  let USDTinstance;

  // ::::::::::::: setRoot-Whitelist ::::::::::::: //

  describe("test of setRoot and isWhitelisted", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
    })

    it("...should revert because of Ownable", async () => {
      await expectRevert(AntkPrivateInstance.setRoot(root, { from: other }), "Ownable: caller is not the owner");
    });

    it("...should return true", async () => {
      const isWhitelisted = await AntkPrivateInstance.isWhitelist(merkleProof2, { from: whitelist10 })
      expect(isWhitelisted).to.be.true
    })

    it("...should return false", async () => {
      const isWhitelisted = await AntkPrivateInstance.isWhitelist(merkleProof2, { from: owner })
      expect(isWhitelisted).to.be.false
    })

  })

  // ::::::::::::: Status ::::::::::::: //
  describe("tests of status", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
    })

    it("...should return salesStatus = 0", async () => {
      const currentStatus = await AntkPrivateInstance.salesStatus()
      expect(BN(currentStatus)).to.be.bignumber.equal(BN(0))
    })

    it("...should revert because of Ownable", async () => {
      await expectRevert(AntkPrivateInstance.changeSalesStatus(2, { from: other }), "Ownable: caller is not the owner");
    })
    it("...should return salesStatus = 1", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      const currentStatus = await AntkPrivateInstance.salesStatus()
      expect(BN(currentStatus)).to.be.bignumber.equal(BN(1))
    })

    it("...should emit newStatus", async () => {
      const event = await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      expectEvent(event, "NewStatus", { newStatus: BN(2) })
    })

  })
  // ::::::::::::: calculNumberOfTokenToBuy ::::::::::::: //

  describe("test of calculNumberOfTokenToBuy", () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: owner })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
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
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
    })

    it("...should revert because of Status", async () => {
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, merkleProof2, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of not whitelisted", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, merkleProof2, { from: other }), "Vous ne pouvez pas investir pour le moment !");
    })

    it("...should revert because of not approve", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, merkleProof2, { from: buyer4 }), "ERC20: insufficient allowance.");
    })

    it("...should revert because of not enough USDT", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 50000000000, { from: buyer5 })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(50000, merkleProof2, { from: buyer5 }), "ERC20: transfer amount exceeds balance.");
    })

    it("...should revert because of minimum amout to buy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 50000000000, { from: buyer4 })
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(0.1, merkleProof2, { from: buyer4 }), "underflow");
    })

    it("...should emit Tokensbuy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      const event = await AntkPrivateInstance.buyTokenWithTether(60000, merkleProof2, { from: buyer4 });
      expectEvent(event, "TokensBuy", { addressBuyer: buyer4, numberOfTokensPurchased: BN(100000000), amountSpendInDollars: BN(60000) })
    })

    it("...should return USDT balance of 30 000x10**6 ", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof2, { from: buyer4 });
      const tokensBuy = await USDTinstance.balanceOf(AntkPrivateInstance.address)
      expect(BN(tokensBuy)).to.be.bignumber.equal(BN(30000000000))
    })

    it("...should return numberOfTokenToSell", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof2, { from: buyer4 });
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
      await AntkPrivateInstance.buyTokenWithTether(100000, merkleProof2, { from: buyer4 });
      await AntkPrivateInstance.buyTokenWithTether(100000, merkleProof2, { from: whitelist1 });
      await AntkPrivateInstance.buyTokenWithTether(100000, merkleProof2, { from: whitelist2 });
      await AntkPrivateInstance.buyTokenWithTether(100000, merkleProof2, { from: whitelist3 });
      await expectRevert(AntkPrivateInstance.buyTokenWithTether(100000, merkleProof2, { from: whitelist4 }), "Il ne reste plus assez de tokens disponibles !")
    })

    it("...should return Tokensbuy = 50000000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof2, { from: buyer4 })
      const buyer = await AntkPrivateInstance.investors(buyer4)
      expect(BN(buyer[0])).to.be.bignumber.equal(BN(50000000))
    })

    it("...should return numberOfTokenToSell = 450000000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof2, { from: buyer4 })
      const numberOfTokenToSell = await AntkPrivateInstance.numberOfTokenToSell()
      expect(BN(numberOfTokenToSell)).to.be.bignumber.equal(BN(450000000))
    })

    it("...should return amounin$ = 30000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof2, { from: buyer4 })
      const buyer = await AntkPrivateInstance.investors(buyer4)
      expect(BN(buyer[1])).to.be.bignumber.equal(BN(30000))
    })

    it("...should return Tokensbonus = 2500000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(15000, merkleProof2, { from: buyer4 })
      const buyer = await AntkPrivateInstance.investors(buyer4)
      expect(BN(buyer[2])).to.be.bignumber.equal(BN(2500000))
    })

    it("...should return numberOfTokenBonus = 2500000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await USDTinstance.approve(AntkPrivateInstance.address, 600000000000, { from: buyer4 })
      await AntkPrivateInstance.buyTokenWithTether(15000, merkleProof2, { from: buyer4 })
      const numberOfTokenBonus = await AntkPrivateInstance.numberOfTokenBonus()
      expect(BN(numberOfTokenBonus)).to.be.bignumber.equal(BN(7500000))
    })

    it("...should return amount$ = 30000 for whitelisted", async () => {
      await USDTinstance.transfer(whitelist1, 100000000000, { from: buyer4 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist1 })
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await AntkPrivateInstance.buyTokenWithTether(30000, merkleProof3, { from: whitelist1 })
      const investor = await AntkPrivateInstance.investors(accounts[1])
      expect(BN(investor[1])).to.be.bignumber.equal(BN(30000))
    })


  })

  // ::::::::::::: buyTokenWithEth ::::::::::::: //

  describe("test of buyTokenWithEth", async () => {

    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: buyer4 })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
    })

    it("...should revert because of status", async () => {
      await expectRevert(AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 }), "Vous ne pouvez pas investir pour le moment !")
    })

    it("...should revert because of status", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 }), "Vous ne pouvez pas investir pour le moment !")
    })

    it("...should return 7500 public", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors(buyer5)
      expect(BN(investor[1])).to.be.bignumber.equal(BN(7500))
    })

    it("...should return 7500 whitelist", async () => {
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth(merkleProof3, { from: accounts[1], value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors(accounts[1])
      expect(BN(investor[1])).to.be.bignumber.equal(BN(7500))
    })

    it("...should return 12 500 000", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 })
      const investor = await AntkPrivateInstance.investors.call(buyer5)
      expect(BN(investor[0])).to.be.bignumber.equal(BN(12500000))
    })

    it("...should emit TokensBuy", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      const event = await AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 })
      expectEvent(event, "TokensBuy", { addressBuyer: buyer5, numberOfTokensPurchased: BN(12500000), amountSpendInDollars: BN(7500) })
    })

    it("...should return balance of ETH", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 })
      const funds = await AntkPrivateInstance.seeFunds()
      expect(funds[1].toString()).to.be.equal('5000000000000000000')
    })

    it("...should revert because of secureETH", async () => {
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.secureBuyEth({ from: owner })
      await expectRevert(AntkPrivateInstance.buyTokenWithEth(merkleProof2, { from: buyer5, value: 5000000000000000000 }), "Vous ne pouvez pas acheter en Eth pour le moment !")
    })


  })

  // ::::::::::::: getFunds ::::::::::::: //

  describe("test of getFunds", async () => {
    beforeEach(async () => {
      USDTinstance = await USDT.new({ from: buyer4 })
      AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: owner })
      await USDTinstance.transfer(accounts[1], 100000000000, { from: buyer4 })
      await USDTinstance.transfer(whitelist2, 100000000000, { from: buyer4 })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: accounts[1] })
      await USDTinstance.approve(AntkPrivateInstance.address, 10000000000000, { from: whitelist2 })
      await AntkPrivateInstance.changeSalesStatus(1, { from: owner })
      await AntkPrivateInstance.buyTokenWithTether(100000, merkleProof3, { from: accounts[1] })
      await AntkPrivateInstance.changeSalesStatus(2, { from: owner })
      await AntkPrivateInstance.buyTokenWithTether(80000, merkleProof3, { from: whitelist2 })
    })

    it("...should return balance owner USDT 180 000", async () => {
      await AntkPrivateInstance.getFunds({ from: owner })
      const balanceUsdt = await USDTinstance.balanceOf(owner)
      expect(BN(balanceUsdt)).to.be.bignumber.equal(BN(180000000000))
    })


  })

})