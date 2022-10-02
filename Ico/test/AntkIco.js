const hre = require("hardhat");
const { expect } = require("chai");

let antkIcoInstance
let [owner, other, other2, other3, other4, other5, other6] = []
// let provider = ethers.getDefaultProvider();
// let balance = await provider.getBalance(owner.address);
// console.log(balance)


describe("Test of changeSalesStatus", async () => {

  beforeEach(async () => {
    [owner, other] = await ethers.getSigners();
    const antkIco = await ethers.getContractFactory("AntkIco");
    antkIcoInstance = await antkIco.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', owner.address)
  })

  it("...should be equal to 0", async function () {
    const status = await antkIcoInstance.salesStatus();
    expect(status).to.equal(0)
  })

  it("...should be equal to 1", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    const status = await antkIcoInstance.salesStatus();
    expect(status).to.equal(1)
  })

  it("...should emit NewStatus", async () => {
    await expect(antkIcoInstance.changeSalesStatus(1)).to.emit(antkIcoInstance, "NewStatus").withArgs(1);
  })

  it("...should revert because of Ownable", async () => {
    await expect(antkIcoInstance.connect(other).changeSalesStatus(1)).to.be.revertedWith("Ownable: caller is not the owner");
  })

})


describe("Test of buy ANTK with ETH", async () => {

  beforeEach(async () => {
    [owner, other, other1, other2, other3, other4, other5, other6] = await ethers.getSigners();
    const antkIco = await ethers.getContractFactory("AntkIco");
    antkIcoInstance = await antkIco.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', owner.address)
  })

  it("...should revert because of status", async () => {
    await expect(antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1", "ether") })).to.be.revertedWith("Vous ne pouvez pas investir pour le moment !");
  })

  it("...should revert because of amount > 150 000$", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await expect(antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("101", "ether") })).to.be.revertedWith("Vous ne pouvez pas investir plus de 150 000 $");
  })

  it("...should revert because of amount < 250 $", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await expect(antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("0.1", "ether") })).to.be.revertedWith("Le montant investi est inferieur au montant minimum !");
  })

  it("...should revert because of : Il n'y a plus assez de jetons disponibles !", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("60", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("90", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("60", "ether") })
    // let numberOfTokenToSell = await antkIcoInstance.numberOfTokenToSell()
    // let balance = await antkIcoInstance.provider.getBalance(antkIcoInstance.address);
    // console.log(ethers.utils.formatEther(balance))
    // console.log(numberOfTokenToSell)
    await expect(antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("17", "ether") })).to.be.revertedWith("Il n'y a plus assez de jetons disponibles !");
  })

  it("...should return numberOfTokensPurchased 1 250 000 ANTK", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1", "ether") })
    const buyer = await antkIcoInstance.investors(other.address)
    expect(buyer[0]).to.equal(1250000)
  })

  it("...should return amount $ = 15000", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1", "ether") })
    const buyer = await antkIcoInstance.investors(other.address)
    expect(buyer[1]).to.equal(1500)
  })

  it("...should return bonus = 125 000 ANTK", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1", "ether") })
    const buyer = await antkIcoInstance.investors(other.address)
    expect(buyer[2]).to.equal(125000)
  })

  it("...should return balance of contract = 1.5 eth", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1.5", "ether") })
    const balance = await antkIcoInstance.provider.getBalance(antkIcoInstance.address);
    expect(ethers.utils.formatEther(balance)).to.equal("1.5")
  })

  it("...should return numberOfTokenToSell = 3998125000", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("1.5", "ether") })
    const numberOfTokenToSell = await antkIcoInstance.numberOfTokenToSell();
    expect(numberOfTokenToSell).to.equal(3998125000)
  })

  it("...should return numberOfTokenBonus = 49 812 500", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("1.5", "ether") })
    const numberOfTokenBonus = await antkIcoInstance.numberOfTokenBonus();
    expect(numberOfTokenBonus).to.equal(49812500)
  })

  it("...should return 115 000 000 ANTK", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    const buyer = await antkIcoInstance.investors(other5.address)
    expect(buyer[0]).to.equal(115000000)
  })

  it("...should return 93333333 ANTK", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other1).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other3).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other4).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    const buyer = await antkIcoInstance.investors(other5.address)
    expect(buyer[0]).to.equal(93333333)
  })

  it("...should emit NewStatus", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await expect(antkIcoInstance.connect(other5).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })).to.emit(antkIcoInstance, "TokensBuy").withArgs(other5.address, 125000000, 150000);
  })
})


describe("Test of getEth", async () => {

  beforeEach(async () => {
    [owner, other] = await ethers.getSigners();
    const antkIco = await ethers.getContractFactory("AntkIco");
    antkIcoInstance = await antkIco.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', owner.address)
  })

  it("...should revert because of ownable", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await expect(antkIcoInstance.connect(other).getEth()).to.be.revertedWith("Ownable: caller is not the owner");
  })
  
  it("...should return balance of ownable", async () => {
    // let provider = ethers.getDefaultProvider();
    let balance = await antkIcoInstance.provider.getBalance(owner.address);
    console.log(balance)
    await antkIcoInstance.changeSalesStatus(1)
    await antkIcoInstance.connect(other2).buyTokenWithEth({ value: ethers.utils.parseUnits("100", "ether") })
    await antkIcoInstance.connect(owner).getEth()
    let newbalance = await antkIcoInstance.provider.getBalance(owner.address);
    console.log(newbalance)
    expect(newbalance).to.equal(balance + 100)

  })

})