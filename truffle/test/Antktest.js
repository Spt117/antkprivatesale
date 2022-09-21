const AntkPrivateTest = artifacts.require("./AntkPrivate.sol");
const USDT = artifacts.require("./USDT.sol");
// const {MerkleTree} = require("merkletreejs")
// const keccak256 = require("keccak256")

const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

contract('AntkPrivateTest', accounts => {

    const ganache = accounts[0]
    const owner = '0x1Bf9Ee786B600A294DFd0151D1aF027a286A8f4B';
    const whitelist1 = '0x39C4Ce965b9F81de90D5F91127afB807bdd1F705';
    const whitelist2 = '0x311EEfAE053Eeb0fB77C750Ee3d84dFd88B2c5b5';
    const other = '0x1dCDc0A79dac4ff8Ed895453dFE89402f7248D04';
    const root = '0x13175a325706e00569533fdcb6cc5014cdfdf56aeecabd25613b7cff497937cc';
    const merkleProof = [0xe4506196644de3e89c3c54b222159d85ec4f190db43b8f73717d0b6d999e5b74,0x2051b23223f6d5d83040309ebe1f9910538fd0d2137237f11cba78178cc7bd37,0xecf69cabc20f2ae0792c63c8208a565313fea1aa62f2c2f36089554a036fce67,0xbb266e6e62b2d273fcc37081216848aec7b90478646fafb132f58fd57271751b,0x08b60d69d596a6ce1e54ff87bdf9e390a4319b701a25bb8abdec4e67ee248487]

    const goerliEthChainlink = '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e';

    let AntkPrivateInstance;
    let USDTinstance;

    // ::::::::::::: setRoot ::::::::::::: //

    describe.only("test of setRoot and isWhitelisted", () => {

        beforeEach(async () => {
            USDTinstance = await USDT.new({ from: ganache })
            AntkPrivateInstance = await AntkPrivateTest.new(USDTinstance.address, goerliEthChainlink, owner, root, { from: ganache })
        })
        console.log(merkleProof)
        it("...should revert because of Ownable", async () => {
            await expectRevert(AntkPrivateInstance.setRoot(merkleProof, { from: other }), "Ownable: caller is not the owner");
        });

        it("...should return true", async () => {
            const isWhitelisted = await AntkPrivateInstance.isWhitelist(merkleProof, {from: whitelist1})
            expect(isWhitelisted).to.be.true
        })

        it("...should return false", async () => {
            const isWhitelisted = await AntkPrivateInstance.isWhitelist(merkleProof, {from: ganache})
            expect(isWhitelisted).to.be.false
        })

    })


})