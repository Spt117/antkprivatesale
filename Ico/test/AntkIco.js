const hre = require("hardhat");
const { expect } = require("chai");

let antkIcoInstance
let [owner, other] = []

describe("test of changeSalesStatus", async () => {

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


describe("Test of buy ANTK with USDT", async () => {
  beforeEach( async () => {
    [owner, other] = await ethers.getSigners();
    const antkIco = await ethers.getContractFactory("AntkIco");
    antkIcoInstance = await antkIco.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', owner.address)
  })
})