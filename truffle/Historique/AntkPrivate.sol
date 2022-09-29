// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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
    uint256 public numberOfTokenToSell = 500000000;
    uint256 public numberOfTokenBonus = 10000000;

    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     * @dev ethPrice is the Chainlink address Price of eth
     * @dev anktWallet is the wallet that will recover the funds
     */
    address immutable usdt;
    address immutable ethPrice;
    address immutable antkWallet;

    /**
     * @dev root is the rootHash of the whitelisted address
     */
    bytes32 private root;

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
        uint256 numberOfTokensPurchased,
        uint256 amountSpendInDollars
    );

    /**
     * @notice Constructor to set address at the deployement
     * @param _usdt is the ERC20 asset to buy Antk
     * @param _ethPrice is the Chainlink address Price of eth
     * @param _antkWallet is the wallet that will recover the funds
     * @param _root is the rootHash of the whitelisted address
     */
    constructor(
        address _usdt,
        address _ethPrice,
        address _antkWallet,
        bytes32 _root
    ) {
        usdt = _usdt;
        ethPrice = _ethPrice;
        antkWallet = _antkWallet;
        root = _root;
    }

    /**
     * @notice check that the purchase parameters are correct
     * @dev called in function buy with ETH and buy with USDT
     * @param _amount is the amount to buy in dollars
     */
    modifier requireToBuy(uint256 _amount, bytes32[] calldata _merkleProof) {
        require(
            (isWhitelist(_merkleProof) && salesStatus == SalesStatus(1)) ||
                salesStatus == SalesStatus(2),
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
     * @notice set the root to set whitelisted address
     * @dev only owner can call this function
     * @param _root is the rootHash of the whitelisted address
     */
    function setRoot(bytes32 _root) external onlyOwner {
        root = _root;
    }

    /**
     * @notice check if the address is whitelisted
     * @param _merkleProof is an array of proof on the webApp
     */
    function isWhitelist(bytes32[] calldata _merkleProof)
        public
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(_merkleProof, root, leaf); // Or you can mint tokens here
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
    function calculNumberOfTokenToBuy(uint256 _amountDollars)
        public
        view
        returns (uint256)
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
    function buyTokenWithTether(
        uint128 _amountDollars,
        bytes32[] calldata _merkleProof
    ) external requireToBuy(_amountDollars, _merkleProof) {
        uint256 numberOfTokenToBuy = calculNumberOfTokenToBuy(_amountDollars);

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * 10**6
        );
        require(result, "Transfer from error");

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
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ethPrice
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price);
    }

    /**
     * @notice buy ANTK with ETH
     * @dev msg.value is the amount of ETH to send buy the buyer
     */
    function buyTokenWithEth(bytes32[] calldata _merkleProof)
        external
        payable
        requireToBuy(
            uint256((msg.value * getLatestPrice()) / 10**26),
            _merkleProof
        )
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
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
     function secureBuyEth() external onlyOwner {
        if(!unactiveEth){unactiveEth=true;}
        else unactiveEth = false;
     }

    /**
     * @notice send the USDT and the ETH to ANTK company
     * @dev only the Owner of the contract can call this function
     */
    function getFunds() external onlyOwner {
        IERC20(usdt).transfer(
            antkWallet,
            IERC20(usdt).balanceOf(address(this))
        );

        (bool sent, ) = antkWallet.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @notice see the USDT and the ETH on the contract
     */
    function seeFunds() external view returns (uint256 USDT, uint256 ETH) {
        return (IERC20(usdt).balanceOf(address(this)), address(this).balance);
    }
}

// address immutable usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
// address immutable ethPrice = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
// address immutable antkWallet = 0x80920A7960670f01f63d6fA9B1f2a2Efd1C2A371;
