// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Private Sale ANTK
 *
 * @notice This contract is a pre sale contract
 *
 * @dev Buyers can buy only with ETH or USDT
 * @dev Can add whitelists address to buy first
 *
 * @dev Implementation of the {IERC20} interface
 * @dev Implementation of the {Ownable} contract
 * @dev Implementation of the {AggregatorV3Interface} contract
 *
 */

contract AntkPrivateTest is Ownable {
    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     */
    address usdt;

    constructor(address _tether) {
        usdt = _tether;
    }

    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev It is update when someone buy
     */
    uint128 public numberOfTokenToSell = 500000000;

    /// save informations about the buyers
    struct Investor {
        bool isWhitelisted;
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        string asset;
    }

    /// buyer's address  => buyer's informations
    mapping(address => Investor) public investors;

    /// status of this sales contract
    enum SalesStatus {
        AdminTime,
        SalesForWhitelist,
        SalesForAll
    }

    /// salesStatus is the status of the sales
    SalesStatus public salesStatus;

    /// event when owner change status
    event newStatus(SalesStatus newStatus);

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint128 numberOfTokensPurchased,
        uint128 amountSpendInDollars
    );

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint128 _amount) {
        require(
            (investors[msg.sender].isWhitelisted &&
                salesStatus == SalesStatus(1)) || salesStatus == SalesStatus(2),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(
            _minimumAmountToBuy(_amount),
            "Ce montant est inferieur au montant minimum !"
        );
        require(
            calculNumberOfTokenToBuy(_amount) <= numberOfTokenToSell,
            "Il ne reste plus assez de tokens disponibles !"
        );
        _;
    }

    fallback() external {}

    receive() external payable {}

    /**
     * @notice add the address to the whitelist
     * @dev only the Owner of the contract can call this function
     * @param _address is an array of address
     */
    function setWhitelist(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            investors[_address[i]].isWhitelisted = true;
        }
    }

    /**
     * @notice change the status of the sale
     * @dev only the Owner of the contract can call this function
     * @param _idStatus is the id of the status
     */
    function changeSalesStatus(uint256 _idStatus) external onlyOwner {
        salesStatus = SalesStatus(_idStatus);

        emit newStatus(SalesStatus(_idStatus));
    }

    /**
     * @notice check the minimum require to buy
     * @dev this is a private function, called in the modifier
     * @param _amountDollars is the amount to buy in dollars
     */
    function _minimumAmountToBuy(uint128 _amountDollars)
        private
        view
        returns (bool)
    {
        if (numberOfTokenToSell > 400000000 && _amountDollars >= 250)
            return true;
        if (numberOfTokenToSell > 300000000 && _amountDollars >= 100)
            return true;
        if (numberOfTokenToSell <= 300000000 && _amountDollars >= 50)
            return true;
        else return false;
    }

    /**
     * @notice calcul number of token to buy
     * @dev this is a public function, called in the modifier and buy function
     * @dev we use it with the dapp to show the number of token to buy
     * @param _amountDollars is the amount to buy in dollars
     */
    function calculNumberOfTokenToBuy(uint128 _amountDollars)
        public
        view
        returns (uint128)
    {
        require(
            _amountDollars <= 100000,
            "Vous ne pouvez pas investir plus de 100 000 $"
        );
        if (numberOfTokenToSell > 400000000) {
            if (
                (numberOfTokenToSell - (_amountDollars * 10000) / 6) >=
                400000000
            ) return (_amountDollars * 10000) / 6;
            else {
                return
                    (numberOfTokenToSell - 400000000) +
                    ((_amountDollars -
                        (((numberOfTokenToSell - 400000000) * 6) / 10000)) /
                        8) *
                    10000;
            }
        } else if (numberOfTokenToSell > 300000000) {
            if (
                (numberOfTokenToSell - (_amountDollars * 10000) / 8) >=
                300000000
            ) return (_amountDollars * 10000) / 8;
            else {
                return
                    (numberOfTokenToSell - 300000000) +
                    (_amountDollars -
                        (((numberOfTokenToSell - 300000000) * 8) / 10000)) *
                    1000;
            }
        } else {
            return _amountDollars * 1000;
        }
    }

    /**
     * @notice buy ANTK with USDT
     * @param _amountDollars is the amount to buy in dollars
     */
    function buyTokenWithTether(uint128 _amountDollars)
        external
        requireToBuy(_amountDollars)
    {
        require(
            IERC20(usdt).allowance(msg.sender, address(this)) >=
                _amountDollars * 10**6,
            "Vous n'avez pas approuve le transfert de Tether !"
        );
        require(
            IERC20(usdt).balanceOf(msg.sender) >= _amountDollars * 10**6,
            "Vous n'avez pas assez de Tether !"
        );

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * 10**6
        );
        require(result, "Transfer from error");

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            _amountDollars
        );
        investors[msg.sender].amountSpendInDollars += _amountDollars;
        investors[msg.sender].asset = "USDT";

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(_amountDollars),
            _amountDollars
        );

        numberOfTokenToSell -= calculNumberOfTokenToBuy(_amountDollars);
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public pure returns (uint128) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        // );
        // (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 price = 150000000000;
        return uint128(uint256(price));
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth()
        external
        payable
        requireToBuy(uint128((msg.value * getLatestPrice()) / 10**26))
    {
        require(
            msg.sender.balance > msg.value,
            "Vous n'avez pas assez d'ETH !"
        );
        uint128 amountInDollars = uint128(
            (msg.value * getLatestPrice()) / 10**26
        );

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            amountInDollars
        );
        investors[msg.sender].amountSpendInDollars += amountInDollars;
        investors[msg.sender].asset = "ETH";

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(amountInDollars),
            amountInDollars
        );

        numberOfTokenToSell -= calculNumberOfTokenToBuy(amountInDollars);
    }

    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getFunds() external onlyOwner {
        IERC20(usdt).transfer(owner(), IERC20(usdt).balanceOf(address(this)));

        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice see the USDT and the ETH on the contract
     */
    function seeFunds() external view returns (uint256 USDT, uint256 ETH) {
        return (IERC20(usdt).balanceOf(address(this)), address(this).balance);
    }
}

// ETH/USD Chainlink (ETH Mainet): 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (8 décimales)
// ETH/USD Chainlink (ETH Goerli Testnet): 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e (8 décimales)

// USDT mainet address 0xdAC17F958D2ee523a2206206994597C13D831ec7 (6 décimales)
// USDC Ropsten for tests : 0x07865c6E87B9F70255377e024ace6630C1Eaa37F (6 décimales)

//Interface     function investors (address _address) external view returns
//(bool isWhitelisted, address referrer, uint numberOfTokensPurchased, uint amountSpendInDollars, string memory asset);

// function getOwnerBalance(address addr) public view returns (uint) {
//     return addr.balance;
// }
