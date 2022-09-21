// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {

    constructor() ERC20("Tether", "USDT") {
        _mint(msg.sender, 1000000000000000000000);

    }
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function getAddr() public view returns (address) {
        return address(this);
    }

}