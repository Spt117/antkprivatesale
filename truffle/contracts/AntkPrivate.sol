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
    struct Investor {
        bool isWhitelisted;
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        string asset;
    }

    enum SalesStatus {
        AdminTime,
        SalesForWhitelist,
        SalesForAll
    }

    SalesStatus public salesStatus;
    mapping(address => Investor) public investors;

    uint128 public numberOfTokenAvaible = 500000000;

    function setWhitelist(address[] memory _address) external onlyOwner {
        for (uint256 i = 0; i < _address.length; i++) {
            investors[_address[i]].isWhitelisted = true;
        }
    }

    function changeSalesStatus(uint256 _idStatus) external onlyOwner {
        salesStatus = SalesStatus(_idStatus);
    }

    modifier requireToBuy(uint128 _amount) {
        require(
            (investors[msg.sender].isWhitelisted &&
                salesStatus == SalesStatus(1)) || salesStatus == SalesStatus(2),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(
            _miniToBuy(_amount),
            "Ce montant est inferieur au montant minimum !"
        );
        require(calculNumberOfTokenToBuy(_amount)<=numberOfTokenAvaible, "Il ne reste plus assez de tokens disponibles !");
        _;
    }

        function _miniToBuy(uint128 _amount) private view returns (bool) {
        if (numberOfTokenAvaible > 400000000 && _amount >= 250) return true;
        if (numberOfTokenAvaible > 300000000 && _amount >= 100) return true;
        if (numberOfTokenAvaible <= 300000000 && _amount >= 50) return true;
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
        if (numberOfTokenAvaible > 400000000) {
            if (
                (numberOfTokenAvaible - (_amountDollars * 10000) / 6) >=
                400000000
            ) return (_amountDollars * 10000) / 6;
            else {
                return
                    (numberOfTokenAvaible - 400000000) +
                    ((_amountDollars -
                        (((numberOfTokenAvaible - 400000000) * 6) / 10000)) /
                        8) *
                    10000;
            }
        } else if (numberOfTokenAvaible > 300000000) {
            if (
                (numberOfTokenAvaible - (_amountDollars * 10000) / 8) >=
                300000000
            ) return (_amountDollars * 10000) / 8;
            else {
                return
                    (numberOfTokenAvaible - 300000000) +
                    (_amountDollars -
                        (((numberOfTokenAvaible - 300000000) * 8) / 10000)) *
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
            (investors[msg.sender].isWhitelisted &&
                salesStatus == SalesStatus(1)) || salesStatus == SalesStatus(2),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(
            IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).balanceOf(
                msg.sender
            ) >= _amountDollars * 10**6,
            "Vous n'avez pas assez de Tether !"
        );
        require(
            IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F).allowance(
                msg.sender,
                address(this)
            ) >= _amountDollars * 10**6,
            "Vous n'avez pas approuve le transfert de Tether !"
        );

        bool result = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F)
            .transferFrom(msg.sender, address(this), _amountDollars * 10**6);
        require(result, "Transfer from error");

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            _amountDollars
        );
        investors[msg.sender].amountSpendInDollars += _amountDollars;
        investors[msg.sender].asset = "USDT";

        numberOfTokenAvaible -= calculNumberOfTokenToBuy(_amountDollars);
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

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(uint128((msg.value * getLatestPrice()) / 10**26));
        investors[msg.sender].amountSpendInDollars += uint128((msg.value * getLatestPrice()) / 10**26);
        investors[msg.sender].asset = "ETH";

        numberOfTokenAvaible -= calculNumberOfTokenToBuy(uint128((msg.value * getLatestPrice()) / 10**26));
    }
}

// ETH/USD Chainlink (ETH Mainet): 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 (8 décimales)
// ETH/USD Chainlink (ETH Goerli Testnet): 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e (8 décimales)

// USDT mainet address 0xdac17f958d2ee523a2206206994597c13d831ec7 (6 décimales)
// USDC Ropsten for tests : 0x07865c6E87B9F70255377e024ace6630C1Eaa37F (6 décimales)

//Interface     function investors (address _address) external view returns
//(bool isWhitelisted, address referrer, uint numberOfTokensPurchased, uint amountSpendInDollars, string memory asset);

// function getOwnerBalance(address addr) public view returns (uint) {
//     return addr.balance;
// }
