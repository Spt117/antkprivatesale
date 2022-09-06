import { EthProvider } from "./contexts/EthContext";
import Demo from "./components/Demo.jsx";
import "./App.css";

function App() {
  return (
    <EthProvider>
      <div id="App" >
        <div className="container">
          <Demo />
        </div>
      </div>
    </EthProvider>
  );
}

export default App;
