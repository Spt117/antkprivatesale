// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Private Sale ANTK
 *
 * @notice This contract is a pre sale contract
 *
 * @author https://antk.io
 *
 * @dev Buyers can buy only with ETH or USDT
 * @dev Can add whitelists address to buy first
 *
 * @dev Implementation of the {Ownable} contract
 *
 */

contract AntkPrivate is Ownable {
    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev numberOfTokenBonus is the number of ANTK in bonus
     * @dev 6.5% if amountInDollars>500$ and 10% if >1500
     * @dev They are update when someone buy
     */
    uint public numberOfTokenToSell = 500000000;
    uint public numberOfTokenBonus = 10000000;

    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     */
    address immutable usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    /// save informations about the buyers
    struct Investor {
        bool isWhitelisted;
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        uint128 bonusTokens;
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
    event NewStatus(SalesStatus newStatus);

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint numberOfTokensPurchased,
        uint amountSpendInDollars
    );

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint _amount) {
        require(
            (investors[msg.sender].isWhitelisted &&
                salesStatus == SalesStatus(1)) || salesStatus == SalesStatus(2),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(_amount >= 1, "Ce montant est inferieur au montant minimum !");
        require(
            calculNumberOfTokenToBuy(_amount) <= numberOfTokenToSell,
            "Il ne reste plus assez de tokens disponibles !"
        );
        _;
    }

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

        emit NewStatus(SalesStatus(_idStatus));
    }

    /**
     * @notice calcul number of token to buy
     * @dev this is a public function, called in the modifier and buy function
     * @dev we use it with the dapp to show the number of token to buy
     * @param _amountDollars is the amount to buy in dollars
     */
    function calculNumberOfTokenToBuy(uint _amountDollars)
        public
        view
        returns (uint)
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

        uint numberOfTokenToBuy = calculNumberOfTokenToBuy(_amountDollars);

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * 10**6
        );
        require(result, "Transfer from error");

        investors[msg.sender].numberOfTokensPurchased += uint128(numberOfTokenToBuy);
        investors[msg.sender].amountSpendInDollars += _amountDollars;

        emit TokensBuy(msg.sender, numberOfTokenToBuy, _amountDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public view returns (uint) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint(price);
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth()
        external
        payable
        requireToBuy(uint((msg.value * getLatestPrice()) / 10**26))
    {
        require(
            msg.sender.balance > msg.value,
            "Vous n'avez pas assez d'ETH !"
        );
        uint amountInDollars = uint(
            (msg.value * getLatestPrice()) / 10**26
        );

        uint numberOfTokenToBuy = calculNumberOfTokenToBuy(amountInDollars);

        investors[msg.sender].numberOfTokensPurchased += uint128(numberOfTokenToBuy);
        investors[msg.sender].amountSpendInDollars += uint128(amountInDollars);

        emit TokensBuy(msg.sender, numberOfTokenToBuy, amountInDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;
    }

    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getFunds() external onlyOwner {
        IERC20(usdt).transfer(0x80920A7960670f01f63d6fA9B1f2a2Efd1C2A371, IERC20(usdt).balanceOf(address(this)));

        (bool sent, ) = 0x80920A7960670f01f63d6fA9B1f2a2Efd1C2A371.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice see the USDT and the ETH on the contract
     */
    function seeFunds() external view returns (uint256 USDT, uint256 ETH) {
        return (IERC20(usdt).balanceOf(address(this)), address(this).balance);
    }
}
