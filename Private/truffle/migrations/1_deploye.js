const AntkPrivate = artifacts.require("AntkPrivate");

module.exports = function (deployer) {
  deployer.deploy(AntkPrivate, '0x05e797F41f54e7Ef542775143B43f0B224B11760', '0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e', '0x1Bf9Ee786B600A294DFd0151D1aF027a286A8f4B', '0x13175a325706e00569533fdcb6cc5014cdfdf56aeecabd25613b7cff497937cc');
};