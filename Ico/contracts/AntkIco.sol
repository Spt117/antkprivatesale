// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../node_modules/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract AntkIco is Ownable {
    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev numberOfTokenBonus is the number of ANTK in bonus
     * @dev 6.5% if amountInDollars>500$ and 10% if >1500
     * @dev They are update when someone buy
     */
    uint256 public numberOfTokenToSell = 4000000000;
    uint256 public numberOfTokenBonus = 50000000;

    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     * @dev ethPrice is the Chainlink address Price of eth
     * @dev anktWallet is the wallet that will recover the funds
     */
    address immutable usdt;
    address immutable ethPrice;
    address payable immutable antkWallet;

    /**
     * @dev activeEth to secure the buyEth if chainlink doesn't work
     */
    bool unactiveEth;

    /// save informations about the buyers
    struct Investor {
        uint128 numberOfTokensPurchased;
        uint128 amountSpendInDollars;
        uint128 bonusTokens;
    }

    /// buyer's address  => buyer's informations
    mapping(address => Investor) public investors;

    /// status of this sales contract
    enum SalesStatus {
        AdminTime,
        Sales
    }

    /// salesStatus is the status of the sales
    SalesStatus public salesStatus;

    /// event when owner change status
    event NewStatus(SalesStatus newStatus);

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint256 numberOfTokensPurchased,
        uint256 amountSpendInDollars
    );

    /**
     * @notice Constructor to set address at the deployement
     * @param _usdt is the ERC20 asset to buy Antk
     * @param _ethPrice is the Chainlink address Price of eth
     * @param _antkWallet is the wallet that will recover the funds
     */
    constructor(
        address _usdt,
        address _ethPrice,
        address payable _antkWallet
    ) {
        usdt = _usdt;
        ethPrice = _ethPrice;
        antkWallet = _antkWallet;
    }

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amountDollars is the amount to buy in dollars
     */
    modifier requireToBuy(uint256 _amountDollars) {
        require(
            (salesStatus == SalesStatus(1)),
            "Vous ne pouvez pas investir pour le moment !"
        );
        require(
            requireAmount(_amountDollars),
            "Le montant investi est inferieur au montant minimum !"
        );
        require(
            _amountDollars <= 150000,
            "Vous ne pouvez pas investir plus de 150 000 $"
        );
        require(
            calculNumberOfTokenToBuy(_amountDollars) <= numberOfTokenToSell,
            "Il n'y a plus assez de jetons disponibles !"
        );

        _;
    }

    /**
     * @notice check minimum and maximum to buy
     * @dev this a private function
     * @param _amountDollars is the amount of dollar to spend
     */
    function requireAmount(uint256 _amountDollars) private view returns (bool) {
        if (numberOfTokenToSell > 3300000000 && _amountDollars >= 250) {
            return true;
        } else if (
            numberOfTokenToSell <= 3300000000 &&
            numberOfTokenToSell > 2600000000 &&
            _amountDollars >= 100
        ) return true;
        else if (numberOfTokenToSell <= 2600000000 && _amountDollars >= 10)
            return true;
        else return false;
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
     * @notice calcul number of token to buy funtion of price
     * @dev this is a private function
     * @param _amountInDollards is the amount to buy in dollars
     */
    function calculNumberOfTokenPhase1(uint256 _amountInDollards)
        private
        pure
        returns (uint256)
    {
        return (_amountInDollards * 10000) / 12;
    }

    function calculNumberOfTokenPhase2(uint256 _amountInDollards)
        private
        pure
        returns (uint256)
    {
        return (_amountInDollards * 10000) / 15;
    }

    function calculNumberOfTokenPhase3(uint256 _amountInDollards)
        private
        pure
        returns (uint256)
    {
        return (_amountInDollards * 10000) / 18;
    }

    /**
     * @notice calcul number of token to buy
     * @dev this is a private function, called in the modifier and buy function
     * @dev we use it with the dapp to show the number of token to buy
     * @param _amountDollars is the amount to buy in dollars
     */
    function calculNumberOfTokenToBuy(uint256 _amountDollars)
        private
        view
        returns (uint256)
    {
        if (numberOfTokenToSell > 3300000000) {
            if (
                numberOfTokenToSell -
                    calculNumberOfTokenPhase1(_amountDollars) >
                3300000000
            ) {
                return calculNumberOfTokenPhase1(_amountDollars);
            } else {
                uint256 tokensPhase1 = numberOfTokenToSell - 3300000000;
                uint256 tokensPhase2 = ((_amountDollars -
                    ((tokensPhase1 * 12) / 10000)) * 10000) / 15;
                return tokensPhase1 + tokensPhase2;
            }
        } else if (numberOfTokenToSell > 2600000000) {
            if (
                numberOfTokenToSell -
                    calculNumberOfTokenPhase2(_amountDollars) >
                2600000000
            ) {
                return calculNumberOfTokenPhase2(_amountDollars);
            } else {
                uint256 tokensPhase2 = numberOfTokenToSell - 2600000000;
                uint256 tokensPhase3 = ((_amountDollars -
                    ((tokensPhase2 * 15) / 10000)) * 10000) / 18;
                return tokensPhase2 + tokensPhase3;
            }
        } else {
            return (_amountDollars * 10000) / 18;
        }
    }

    /**
     * @notice set the bonus to the buyer
     * @param _numberToken is the number of token buy
     * @param _amountDollars is the price in dollars
     */
    function _setBonus(uint128 _numberToken, uint128 _amountDollars) private {
        uint128 bonus;
        if (_amountDollars >= 1500) {
            if (numberOfTokenBonus >= _numberToken / 10) {
                bonus = _numberToken / 10;
            } else bonus = uint128(numberOfTokenBonus);
        } else {
            if (numberOfTokenBonus >= (_numberToken * 65) / 1000) {
                bonus = (_numberToken * 65) / 1000;
            } else {
                bonus = uint128(numberOfTokenBonus);
            }
        }
        investors[msg.sender].bonusTokens += bonus;
        numberOfTokenBonus -= bonus;
    }

    /**
     * @notice buy ANTK with USDT
     * @param _amountDollars is the amount to buy in dollars
     */
    function buyTokenWithTether(uint128 _amountDollars)
        external
        requireToBuy(_amountDollars)
    {
        uint256 numberOfTokenToBuy = calculNumberOfTokenToBuy(_amountDollars);

        SafeERC20.safeTransferFrom(
            IERC20(usdt),
            msg.sender,
            address(this),
            _amountDollars
        );

        investors[msg.sender].numberOfTokensPurchased += uint128(
            numberOfTokenToBuy
        );
        investors[msg.sender].amountSpendInDollars += _amountDollars;

        emit TokensBuy(msg.sender, numberOfTokenToBuy, _amountDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;

        if (_amountDollars >= 500 && numberOfTokenBonus > 0) {
            _setBonus(uint128(numberOfTokenToBuy), uint128(_amountDollars));
        }
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(ethPrice);
        // (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(150000000000);
    }

    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function secureBuyEth() external onlyOwner {
        if (!unactiveEth) {
            unactiveEth = true;
        } else unactiveEth = false;
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth()
        external
        payable
        requireToBuy(uint256((msg.value * getLatestPrice()) / 10**26))
    {
        require(
            !unactiveEth,
            "Vous ne pouvez pas acheter en Eth pour le moment !"
        );
        uint256 amountInDollars = uint256(
            (msg.value * getLatestPrice()) / 10**26
        );

        uint256 numberOfTokenToBuy = calculNumberOfTokenToBuy(amountInDollars);

        investors[msg.sender].numberOfTokensPurchased += uint128(
            numberOfTokenToBuy
        );
        investors[msg.sender].amountSpendInDollars += uint128(amountInDollars);

        emit TokensBuy(msg.sender, numberOfTokenToBuy, amountInDollars);

        numberOfTokenToSell -= numberOfTokenToBuy;

        if (amountInDollars >= 500 && numberOfTokenBonus > 0) {
            _setBonus(uint128(numberOfTokenToBuy), uint128(amountInDollars));
        }
    }

    /**
     * @notice send the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getEth() external onlyOwner {
        (bool sent, ) = antkWallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice send the USDT to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getUsdt() external onlyOwner {
        SafeERC20.safeTransfer(
            IERC20(usdt),
            antkWallet,
            IERC20(usdt).balanceOf(address(this))
        );
    }
}