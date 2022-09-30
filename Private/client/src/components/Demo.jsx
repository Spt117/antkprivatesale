import { useState, useEffect } from "react";
import { useEth } from "../contexts/EthContext";

function Demo() {
    const { state: {contract, accounts} } = useEth();
    const [value, setValue] = useState("?");
    
    // async function setTheValue() {
    //     await contract.methods.write(value).send({from : accounts[0]})
    // }

    // function handleInputText(e) {
    //     setValue(e.target.value)
    // }

    // async function returnValue() {
    //     const val = await contract.methods.read().call({ from: accounts[0] });
    //     setValue1(val);
    //     console.log(val)
    // }
    useEffect(() => {
        if (contract) {
            getLatestPrice()
        }
    });
    async function getLatestPrice(){
        const val = await contract.methods.getLatestPrice().call({ from: accounts[0] });
        setValue(val/100000000);
    }
    

    return (
        <div>
            <h1>Test de mes fonctions</h1>

            <div>
            {/* <button onClick={getLatestPrice}>Return the value</button> */}
            
            <p>Prix de l'ETH : ${value}</p>
            </div>
        </div>
    );
}

export default Demo;