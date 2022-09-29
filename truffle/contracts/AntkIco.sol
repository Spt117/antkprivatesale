// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
    address immutable antkWallet;

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
        address _antkWallet
    ) {
        usdt = _usdt;
        ethPrice = _ethPrice;
        antkWallet = _antkWallet;
    }

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint256 _amount) {
        require(
            (salesStatus == SalesStatus(1)),
            "Vous ne pouvez pas investir pour le moment !"
        );
        _;
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
}
