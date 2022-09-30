const { expect } = require("chai");
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');

// // ::::::::::::: testStatus ::::::::::::: //

// describe("test of changeSalesStatus", () => {
//   beforeEach(async () => {

//     // USDTinstance = await USDT.new({ from: owner })
//     // AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, { from: owner })

//   })
//   it("...should emit newStatus", async () => {
//     const [owner] = await ethers.getSigners();
//     const AntkIco = await ethers.getContractFactory("AntkIco");
//     console.log(AntkIco.ContractFactory())
//     const event = await AntkIco.changeSalesStatus(1, { from: owner })
//     expectEvent(event, "newStatus", { newStatus: BN(1) })
//   })

// })
let antkIcoInstance;
let owner = [0];
let other = "0xBD076BeD61C423416A6B91E3490BB80dA64B46ea";
describe("test of changeSalesStatus", function () {

  beforeEach(async () => {
    [owner] = await ethers.getSigners();
    const antkIco = await ethers.getContractFactory("AntkIco");
    antkIcoInstance = await antkIco.deploy('0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', owner.address)
  })

  it("to be equal to 0", async function () {
    const status = await antkIcoInstance.salesStatus();
    expect(status).to.equal(0)
  })

  it("to be equal to 1", async () => {
    await antkIcoInstance.changeSalesStatus(1)
    const status = await antkIcoInstance.salesStatus();
    expect(status).to.equal(1)
  })

  it("...should emit NewStatus", async () => {
    await expect(antkIcoInstance.changeSalesStatus(1)).to.emit(antkIcoInstance, "NewStatus")
  })

  // it("...should revert because of Ownable", async () => {
  //   await antkIcoInstance.connect(signers[1]).mint(signers[0].address, 1001);
  //   await expectRevert(antkIcoInstance.changeSalesStatus(1, { from: other }), "Ownable: caller is not the owner");
  // })

})