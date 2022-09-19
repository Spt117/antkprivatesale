// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//Imports avec @ directement c'est mieux (@openzepplin/contracts/...)
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
 //Le contrat n'implémente pas cette interface
 * @dev Implementation of the {IERC20} interface 
 * @dev Implementation of the {Ownable} contract
 //Celle là non plus
 * @dev Implementation of the {AggregatorV3Interface} contract
 *
 */

contract AntkPrivate is Ownable {


    //Les décimales sont prises en compte ? (attention usdt/usdc pas les même décimales)

    /**
     * @dev numberOfTokenToSell is the number of ANTK to sell
     * @dev It is update when someone buy
     */
    uint128 public numberOfTokenToSell = 500000000;


    //Meilleure pratique : passer l'adresse dans le constructeur et déclarer cette variable en immutable
    /**
     * @dev tether is the only ERC20 asset to buy ANTK
     */
    address usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;


    //Un buyer ne peut donc pas investir en ETH et en USDT ?
    //isWhitelisted : technique pas très efficace pour tout stocker, sauf si déploiement sur un L2/BSC (mais même là pas ouf)
    //Asset : string type pas opti, utiliser une enum à la place

    /**
        enum AssetType {
            ETH,
            USDT,
            UDSC
        }
     */

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


    //Natspec events ?

    //OUblie pas le N majuscule
    /// event when owner change status
    event NewStatus(SalesStatus newStatus);

    //Moins optimisé de mettre des uint128 -> L'EVM est faite pour des uint256 donc plus de boulot à faire 
    // Sur des types moins gros
    //Seul endroit où c'est bien : calldata, struct packing

    /// event when someone buy
    event TokensBuy(
        address addressBuyer,
        uint128 numberOfTokensPurchased,
        uint128 amountSpendInDollars
    );

    //Même remarque tout le long du contrat sur les uint128

    //Require marche bien, façon plus moderne : Custom errors

    //Séparer le modifiers en plusieurs : plus testable, plus cohérent
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

    //Façon la - efficace de stocker les WL (ie : 1000WL ~ 5K$) 
    //Meilleures façons : Merkle Tree, Signed Message

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



    //Internal plus justifié que private je pense
    //Pas très clair l'intérêt de cette fonction. Plus il reste de tokens plus le mininum à acheter est élevé ?
    //Attention à la fin ça va être compliqué de terminer les derniers tokens
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

    /*

        /!\ Attention aux décimales de ERC-20

    */

    //Mieux de casse cette fonction avec des petites fonctions internes bien nommées :
    // + de lisibilité
    // quasiment pas de frais supplémentaires (0 frais supplémentaires si les fcts sont pure)

    //On comprend pas trop ce que tu calcules là
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
                _amountDollars * 10**6, //Un peu sale les décimales hardcodé. Une constante aurait été plus propre (pas de frais supplémentaires)
                //Ou alors utiliser directement le bon montant et faire les conversions dans la dapp
            "Vous n'avez pas approuve le transfert de Tether !"
        );
        //Même chose ici. T'es pas obligé d'appeler cette fonction au pire le transfer passe pas et tu revert. Tu peux indiquer sur la dapp si
        // l'utilisateur a les fonds nécessaires.
        require(
            IERC20(usdt).balanceOf(msg.sender) >= _amountDollars * 10**6,
            "Vous n'avez pas assez de Tether !"
        );

        bool result = IERC20(usdt).transferFrom(
            msg.sender,
            address(this),
            _amountDollars * 10**6
        );
        require(result, "Transfer from error"); //Very good

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            _amountDollars
        );
        investors[msg.sender].amountSpendInDollars += _amountDollars;
        investors[msg.sender].asset = "USDT"; //Tu overwrite ça si il y avait déjà ETH

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(_amountDollars),
            _amountDollars
        );

        numberOfTokenToSell -= calculNumberOfTokenToBuy(_amountDollars); 

        //Apelle une seule fois calculNumberOfTokenToBuy et stocke le résultat dans une variable
    }

    /**
     * @notice Get price of ETH in $ with Chainlink
     */
    function getLatestPrice() public view returns (uint128) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 //Stocke cette adresse en tant qu'immutable que tu fais passer en paramètre du constracteur
            //Plus facile pour les tests comme ça aussi
        );
        (, int256 price, , , ) = priceFeed.latestRoundData(); //Attention aux décimales, elles sont passées en params de latestRoundData
        //Tu devrais mettre en place des mesures de sécurité si l'oracle ne répond plus
        // Par exemple en regardant le dernier timestamp passé par latestRoundData et en mettant une limite :
        // Si ce timestamp est vieux de plus de XX heures j'arrête cette fonction : il y a eu un pb dans l'oracle

        //Tu pourrais stocker l'adresse de l'agregator en variable et pourvoir la changer si un pb se passe 

        return uint128(uint256(price)); //D'après la doc le prix est en 'int'. Attention avec les conversions int/uint tu peux avoir des surprises
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
            (msg.value * getLatestPrice()) / 10**26 // ??? T'es sûr de ton coup ?
            //Fais vraiment attention à tes décimales et hésites pas à les nommer et à utiliser des constantes dans le code
            // ex: USDT_DECIMALS = 6; ETH_DECIMALS = 18
            //Pas de frais en plus sur les constantes
        );

        investors[msg.sender]
            .numberOfTokensPurchased += calculNumberOfTokenToBuy(
            amountInDollars
        );
        investors[msg.sender].amountSpendInDollars += amountInDollars;
        investors[msg.sender].asset = "ETH"; //Même chose, override du précedent si pas le même

        emit TokensBuy(
            msg.sender,
            calculNumberOfTokenToBuy(amountInDollars),
            amountInDollars
        );

        numberOfTokenToSell -= calculNumberOfTokenToBuy(amountInDollars); //Pas de check que c'est > 0 ?
        //Normalement underflow détecté et la tx est revert mais on sait jamais
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