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
 */

contract AntkPrivate is Ownable {
    uint128 public numberOfTokenToSell = 500000000;
    address tether = 0xdAC17F958D2ee523a2206206994597C13D831ec7 ;

    struct Investor {
        bool isWhitelisted;
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        string asset;
    }

    mapping(address => Investor) public investors;

    enum SalesStatus {
        AdminTime,
        SalesForWhitelist,
        SalesForAll
    }

    SalesStatus public salesStatus;

    event TokensBuy(
        address addressBuyer,
        uint128 numberOfTokensPurchased,
        uint128 amountSpendInDollars
    );

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

    function setWhitelist(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            investors[_address[i]].isWhitelisted = true;
        }
    }

    function changeSalesStatus(uint256 _idStatus) external onlyOwner {
        salesStatus = SalesStatus(_idStatus);
    }

    function _minimumAmountToBuy(uint128 _amount) private view returns (bool) {
        if (numberOfTokenToSell > 400000000 && _amount >= 250) return true;
        if (numberOfTokenToSell > 300000000 && _amount >= 100) return true;
        if (numberOfTokenToSell <= 300000000 && _amount >= 50) return true;
        else return false;
    }

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

    function buyTokenWithTether(uint128 _amountDollars)
        external
        requireToBuy(_amountDollars)
    {
        require(
            IERC20(tether).balanceOf(
                msg.sender
            ) >= _amountDollars * 10**6,
            "Vous n'avez pas assez de Tether !"
        );
        require(
            IERC20(tether).allowance(
                msg.sender,
                address(this)
            ) >= _amountDollars * 10**6,
            "Vous n'avez pas approuve le transfert de Tether !"
        );

        bool result = IERC20(tether)
            .transferFrom(msg.sender, address(this), _amountDollars * 10**6);
        require(result, "Transfer from error");

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            _amountDollars
        );
        investors[msg.sender].amountSpendInDollars += _amountDollars;
        investors[msg.sender].asset = "USDT";

        numberOfTokenToSell -= calculNumberOfTokenToBuy(_amountDollars);

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(_amountDollars),
            _amountDollars
        );
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public view returns (uint128) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint128(uint256(price));
    }

    /**
     * @notice Buy Antk with ETH
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

        numberOfTokenToSell -= calculNumberOfTokenToBuy(amountInDollars);

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(amountInDollars),
            amountInDollars
        );
    }

    function getFunds() external onlyOwner {
        IERC20(tether).transfer(
            owner(),
            IERC20(tether).balanceOf(
                address(this)
            )
        );

        (bool sent, ) = owner().call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
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
