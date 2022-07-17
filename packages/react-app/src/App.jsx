import { Alert, Button, Col, Menu, Row } from "antd";
import { StarField, useStarField, StarFieldState, createStarsState } from "starfield-react";
import "antd/dist/antd.css";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useGasPrice,
  useOnBlock,
  useUserProviderAndSigner,
} from "eth-hooks";
import { useExchangeEthPrice } from "eth-hooks/dapps/dex";
import React, { useCallback, useEffect, useState, useRef } from "react";
import { Link, Route, Switch, useLocation } from "react-router-dom";
import "./App.css";
import {
  Account,
  Address,
  Contract,
  Faucet,
  GasGauge,
  Header,
  Ramp,
  ThemeSwitch,
  NetworkDisplay,
  FaucetHint,
} from "./components";
import { NETWORKS, ALCHEMY_KEY } from "./constants";
import externalContracts from "./contracts/external_contracts";
// contracts
import deployedContracts from "./contracts/hardhat_contracts.json";
import { Transactor, Web3ModalSetup } from "./helpers";
import { YourExos, Exos } from "./views";
import { useStaticJsonRPC } from "./hooks";

const { ethers } = require("ethers");
/*
    Welcome to 🏗 scaffold-eth !

    Code:
    https://github.com/scaffold-eth/scaffold-eth

    Support:
    https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA
    or DM @austingriffith on twitter or telegram

    You should get your own Infura.io ID and put it in `constants.js`
    (this is your connection to the main Ethereum network for ENS etc.)


    🌏 EXTERNAL CONTRACTS:
    You can also bring in contract artifacts in `constants.js`
    (and then use the `useExternalContractLoader()` hook!)
*/

/// 📡 What chain are your contracts deployed to?
const targetNetwork = NETWORKS.localhost; // <------- select your target frontend network (localhost, rinkeby, xdai, mainnet)

const BufferList = require("bl/BufferList");

// 😬 Sorry for all the console logging
const DEBUG = false;
const NETWORKCHECK = false;

// 🛰 providers
if (DEBUG) console.log("📡 Connecting to Mainnet Ethereum");

// 🔭 block explorer URL
const blockExplorer = targetNetwork.blockExplorer;

const web3Modal = Web3ModalSetup();

// 🛰 providers
const providers = [
  "https://eth-mainnet.gateway.pokt.network/v1/lb/611156b4a585a20035148406",
  `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
  "https://rpc.scaffoldeth.io:48544",
];

function App(props) {
  const [injectedProvider, setInjectedProvider] = useState();
  const [address, setAddress] = useState();
  const location = useLocation();

  // load all your providers
  const localProvider = useStaticJsonRPC([
    process.env.REACT_APP_PROVIDER ? process.env.REACT_APP_PROVIDER : targetNetwork.rpcUrl,
  ]);
  const mainnetProvider = useStaticJsonRPC(providers);

  const logoutOfWeb3Modal = async () => {
    await web3Modal.clearCachedProvider();
    if (injectedProvider && injectedProvider.provider && typeof injectedProvider.provider.disconnect == "function") {
      await injectedProvider.provider.disconnect();
    }
    setTimeout(() => {
      window.location.reload();
    }, 1);
  };

  /* 💵 This hook will get the price of ETH from 🦄 Uniswap: */
  const price = useExchangeEthPrice(targetNetwork, mainnetProvider);

  /* 🔥 This hook will get the price of Gas from ⛽️ EtherGasStation */
  const gasPrice = useGasPrice(targetNetwork, "fast");
  // Use your injected provider from 🦊 Metamask or if you don't have it then instantly generate a 🔥 burner wallet.
  const userProviderAndSigner = useUserProviderAndSigner(injectedProvider, localProvider);
  const userSigner = userProviderAndSigner.signer;

  useEffect(() => {
    async function getAddress() {
      if (userSigner) {
        const newAddress = await userSigner.getAddress();
        setAddress(newAddress);
      }
    }
    getAddress();
  }, [userSigner]);

  // You can warn the user if you would like them to be on a specific network
  const localChainId = localProvider && localProvider._network && localProvider._network.chainId;
  const selectedChainId =
    userSigner && userSigner.provider && userSigner.provider._network && userSigner.provider._network.chainId;

  // For more hooks, check out 🔗eth-hooks at: https://www.npmjs.com/package/eth-hooks

  // The transactor wraps transactions and provides notificiations
  const tx = Transactor(userSigner, gasPrice);

  // 🏗 scaffold-eth is full of handy hooks like this one to get your balance:
  const yourLocalBalance = useBalance(localProvider, address);

  // Just plug in different 🛰 providers to get your balance on different chains:
  const yourMainnetBalance = useBalance(mainnetProvider, address);

  // const contractConfig = useContractConfig();

  const contractConfig = { deployedContracts: deployedContracts || {}, externalContracts: externalContracts || {} };

  // Load in your local 📝 contract and read a value from it:
  const readContracts = useContractLoader(localProvider, contractConfig);

  // If you want to make 🔐 write transactions to your contracts, use the userSigner:
  const writeContracts = useContractLoader(userSigner, contractConfig, localChainId);

  // EXTERNAL CONTRACT EXAMPLE:
  //
  // If you want to bring in the mainnet DAI contract it would look like:
  const mainnetContracts = useContractLoader(mainnetProvider, contractConfig);

  // If you want to call a function on a new block
  useOnBlock(mainnetProvider, () => {
    console.log(`⛓ A new mainnet block is here: ${mainnetProvider._lastBlockNumber}`);
  });

  const priceToMint = useContractReader(readContracts, "YourCollectible", "price");
  if (DEBUG) console.log("🤗 priceToMint:", priceToMint);

  const totalSupply = useContractReader(readContracts, "YourCollectible", "totalSupply");
  if (DEBUG) console.log("🤗 totalSupply:", totalSupply);
  // const loogiesLeft = 512 - totalSupply;

  // keep track of a variable from the contract in the local React state:
  const balance = useContractReader(readContracts, "YourCollectible", "balanceOf", [address]);
  if (DEBUG) console.log("🤗 address: ", address, " balance:", balance);

  //
  // 🧠 This effect will update yourCollectibles by polling when your balance changes
  //
  const yourBalance = balance && balance.toNumber && balance.toNumber();
  const [yourCollectibles, setYourCollectibles] = useState();
  const [transferToAddresses, setTransferToAddresses] = useState({});
  const [warpWhenReady, setWarpWhenReady] = useState(false);

  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
        try {
          if (DEBUG) console.log("Getting token index", tokenIndex);
          const tokenId = await readContracts.YourCollectible.tokenOfOwnerByIndex(address, tokenIndex);
          if (DEBUG) console.log("Getting Loogie tokenId: ", tokenId);
          const tokenURI = await readContracts.YourCollectible.getTokenURI(tokenId, true);
          if (DEBUG) console.log("tokenURI: ", tokenURI);
          const jsonManifestString = atob(tokenURI.substring(29));

          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            collectibleUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }
        } catch (e) {
          console.log(e);
        }
      }
      console.log(collectibleUpdate);
      setYourCollectibles(collectibleUpdate.reverse());
      if (warpWhenReady) {
        setCurrentSystemId(collectibleUpdate[0].id.toNumber());
        setWarpWhenReady(false);
      }
    };
    updateYourCollectibles();
  }, [address, yourBalance]);

  //
  // 🧫 DEBUG 👨🏻‍🔬
  //
  useEffect(() => {
    if (
      DEBUG &&
      mainnetProvider &&
      address &&
      selectedChainId &&
      yourLocalBalance &&
      yourMainnetBalance &&
      readContracts &&
      writeContracts &&
      mainnetContracts
    ) {
      console.log("_____________________________________ 🏗 scaffold-eth _____________________________________");
      console.log("🌎 mainnetProvider", mainnetProvider);
      console.log("🏠 localChainId", localChainId);
      console.log("👩‍💼 selected address:", address);
      console.log("🕵🏻‍♂️ selectedChainId:", selectedChainId);
      console.log("💵 yourLocalBalance", yourLocalBalance ? ethers.utils.formatEther(yourLocalBalance) : "...");
      console.log("💵 yourMainnetBalance", yourMainnetBalance ? ethers.utils.formatEther(yourMainnetBalance) : "...");
      console.log("📝 readContracts", readContracts);
      console.log("🌍 DAI contract on mainnet:", mainnetContracts);
      console.log("🔐 writeContracts", writeContracts);
    }
  }, [
    mainnetProvider,
    address,
    selectedChainId,
    yourLocalBalance,
    yourMainnetBalance,
    readContracts,
    writeContracts,
    mainnetContracts,
  ]);

  const loadWeb3Modal = useCallback(async () => {
    const provider = await web3Modal.connect();
    setInjectedProvider(new ethers.providers.Web3Provider(provider));

    provider.on("chainChanged", chainId => {
      console.log(`chain changed to ${chainId}! updating providers`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    provider.on("accountsChanged", () => {
      console.log(`account changed!`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    // Subscribe to session disconnection
    provider.on("disconnect", (code, reason) => {
      console.log(code, reason);
      logoutOfWeb3Modal();
    });
  }, [setInjectedProvider]);

  useEffect(() => {
    if (web3Modal.cachedProvider) {
      loadWeb3Modal();
    }
  }, [loadWeb3Modal]);

  const [system, setSystem] = useState(null);

  const [time, setTime] = useState(0);
  const interval = useRef(null);
  const [hasReachedLimit, setHasReachedLimit] = useState(true);

  const [speed, setSpeed] = useState(0);
  const [moving, setMoving] = useState(false);
  useEffect(() => {
    if (moving && speed <= 30) {
      setSpeed(speed + 1);
      if (speed >= 30) {
        setHasReachedLimit(true);
      }
    }
    if (!moving && speed > 0) {
      setSpeed(speed - 1);
      if (speed <= 1) {
        setHasReachedLimit(true);
      }
    }
  }, [time]);

  useEffect(() => {
    if (!hasReachedLimit) {
      if (moving) {
        interval.current = setInterval(() => {
          setTime(t => t + 70);
        }, 70);
      } else if (!moving) {
        interval.current = setInterval(() => {
          setTime(t => t + 100);
        }, 100);
      }
    } else {
      clearInterval(interval.current);
      interval.current = null;
      setTime(0);
    }

    return () => {
      clearInterval(interval.current);
    };
  }, [hasReachedLimit]);

  const getSystemURI = async systemId => {
    const systemURI = await await readContracts.YourCollectible.getTokenURI(systemId, true);
    return systemURI;
  };

  const [height, setHeight] = useState(1);
  const [opacity, setOpacity] = useState(0);
  const [currentSystemId, setCurrentSystemId] = useState(null);
  useEffect(() => {
    const warpToSystem = async systemId => {
      setOpacity(0);
      setHasReachedLimit(false);
      setMoving(true);
      setTimeout(() => setHeight(1), 500);
      const uri = await getSystemURI(systemId, true);
      const jsonManifestString = atob(uri.substring(29));
      const jsonManifest = JSON.parse(jsonManifestString);
      setSystem(jsonManifest);
      setTimeout(async () => {
        setHasReachedLimit(false);
        setMoving(false);
        setTimeout(() => {
          setOpacity(1);
          // <img class="system-img"> height must be multiple of 10 or some SVG animations are too fast in Chrome
          setHeight(window.innerHeight - window.innerHeight % 10);
        }, 1100);
      }, 4000);
    };
    if (typeof currentSystemId == "number") {
      warpToSystem(currentSystemId);
    }
  }, [currentSystemId]);

  const faucetAvailable = localProvider && localProvider.connection && targetNetwork.name.indexOf("local") !== -1;

  return (
    <div className="App">
      <div className="system-img-container">
        {system ? (
          <img
            className="system-img"
            src={system.image}
            alt={system.name}
            style={{ height: height, opacity: opacity }}
          />
        ) : (
          ""
        )}
      </div>
      <StarField
        id="starfield"
        width={window.innerWidth}
        height={window.innerHeight}
        speed={speed * 4}
        count={120}
        fps={60}
        starRatio={365}
        clear={true}
        starSize={2}
        starShape={"square"}
      />
      {/* ✏️ Edit the header and change the title to your project name */}
      <Header />
      <NetworkDisplay
        NETWORKCHECK={NETWORKCHECK}
        localChainId={localChainId}
        selectedChainId={selectedChainId}
        targetNetwork={targetNetwork}
      />
      <Menu
        style={{ textAlign: "left", position: "absolute", zIndex: 2 }}
        selectedKeys={[currentSystemId]}
        mode="vertical"
      >
        <Menu.Item key="mint" onClick={async () => {
            const priceRightNow = await readContracts.YourCollectible.price();
            try {
              const txCur = await tx(
                writeContracts.YourCollectible.mintItem({ value: priceRightNow, gasLimit: 200000 }),
              ); // 300000
              await txCur.wait();
              setWarpWhenReady(true);
            } catch (e) {
              console.log("mint failed", e);
            }
          }}>
          Locate New System (Ξ{priceToMint && (+ethers.utils.formatEther(priceToMint)).toFixed(4)})
        </Menu.Item>
        {/* <Menu.Item key="/yourExos">
          <Link to="/yourExos">Your Exos</Link>
        </Menu.Item>
        <Menu.Item key="/about">
          <Link to="/about">About</Link>
        </Menu.Item>
        <Menu.Item key="/debug">
          <Link to="/debug">Debug Contracts</Link>
        </Menu.Item> */}
        <Menu.ItemGroup title="Located Systems">
          {yourCollectibles
            ? yourCollectibles.map(c => (
                <Menu.Item
                  key={c.id.toNumber()}
                  onClick={() => {
                    setCurrentSystemId(c.id.toNumber());
                  }}
                >
                  {c.name}
                </Menu.Item>
              ))
            : ""}
        </Menu.ItemGroup>
      </Menu>

      {/* <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32, position: "absolute", zIndex: 2 }}>
        <div style={{ height: "10px" }}></div>
        <Button
          type="primary"
          onClick={async () => {
            const priceRightNow = await readContracts.YourCollectible.price();
            try {
              const txCur = await tx(
                writeContracts.YourCollectible.mintItem({ value: priceRightNow, gasLimit: 200000 }),
              ); // 300000
              await txCur.wait();
              setWarpWhenReady(true);
            } catch (e) {
              console.log("mint failed", e);
            }
          }}
        >
          MINT for Ξ{priceToMint && (+ethers.utils.formatEther(priceToMint)).toFixed(4)}
        </Button>
        <p style={{ fontWeight: "bold" }}>{loogiesLeft} left</p>
        <Button
          type="primary"
          onClick={() => {
            console.log("setting moving", moving);
            setCurrentSystemId(0);
          }}
        >
          Move to star
        </Button>
      </div> */}

      <Switch>
        <Route exact path="/">
          {/* <Exos
            readContracts={readContracts}
            mainnetProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            totalSupply={totalSupply}
            DEBUG={DEBUG}
          /> */}
        </Route>
        <Route exact path="/yourExos">
          <YourExos
            readContracts={readContracts}
            writeContracts={writeContracts}
            priceToMint={priceToMint}
            yourCollectibles={yourCollectibles}
            tx={tx}
            mainnetProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            transferToAddresses={transferToAddresses}
            setTransferToAddresses={setTransferToAddresses}
            address={address}
          />
        </Route>
        <Route exact path="/about">
          <div style={{ fontSize: 18, width: 820, margin: "auto" }}>
            <h2 style={{ fontSize: "2em", fontWeight: "bold" }}>About Exos</h2>
            {/* <div style={{ textAlign: "left", marginLeft: 50, marginBottom: 50 }}>
              <ul>
                <li>
                  Go to <a target="_blank" href="https://chainid.link/?network=optimism">https://chainid.link/?network=optimism</a>
                </li>
                <li>
                  Click on <strong>connect</strong> to add the <strong>Optimistic Ethereum</strong> network in <strong>MetaMask</strong>.
                </li>
              </ul>
            </div>
            <h2 style={{ fontSize: "2em", fontWeight: "bold" }}>How to add funds to your wallet on Optimistic Ethereum network</h2>
            <div style={{ textAlign: "left", marginLeft: 50, marginBottom: 100 }}>
              <ul>
                <li><a href="https://portr.xyz/" target="_blank">The Teleporter</a>: the cheaper option, but with a 0.05 ether limit per transfer.</li>
                <li><a href="https://gateway.optimism.io/" target="_blank">The Optimism Gateway</a>: larger transfers and cost more.</li>
                <li><a href="https://app.hop.exchange/send?token=ETH&sourceNetwork=ethereum&destNetwork=optimism" target="_blank">Hop.Exchange</a>: where you can send from/to Ethereum mainnet and other L2 networks.</li>
              </ul>
            </div> */}
          </div>
        </Route>
        <Route exact path="/debug">
          <div style={{ padding: 32 }}>
            <Address value={readContracts && readContracts.YourCollectible && readContracts.YourCollectible.address} />
          </div>
          <Contract
            name="PopulateSystemLayoutStructs"
            price={price}
            signer={userSigner}
            provider={localProvider}
            address={address}
            blockExplorer={blockExplorer}
            contractConfig={contractConfig}
          />
          <Contract
            name="YourCollectible"
            price={price}
            signer={userSigner}
            provider={localProvider}
            address={address}
            blockExplorer={blockExplorer}
            contractConfig={contractConfig}
          />
        </Route>
      </Switch>
      {/* 👨‍💼 Your account is in the top right with a wallet at connect options */}
      <div style={{ position: "fixed", textAlign: "right", right: 0, top: 0, padding: 10, zIndex: 2 }}>
        <Account
          address={address}
          localProvider={localProvider}
          userSigner={userSigner}
          mainnetProvider={mainnetProvider}
          price={price}
          web3Modal={web3Modal}
          loadWeb3Modal={loadWeb3Modal}
          logoutOfWeb3Modal={logoutOfWeb3Modal}
          blockExplorer={blockExplorer}
        />
        <FaucetHint localProvider={localProvider} targetNetwork={targetNetwork} address={address} />
      </div>
      <div style={{ position: "absolute", bottom: 10, width: "100%", margin: "auto", zIndex: 2 }}>
        <Button
          type="primary"
          style={{ float: "right", marginRight: 10 }}
          target="_blank"
          href="https://testnets.opensea.io/collection/exos-v4"
        >View Collection On OpenSea</Button>
        {system ? (
          <Button
            type="primary"
            style={{ float: "right", marginRight: 10 }}
            target="_blank"
            href={"https://testnets.opensea.io/assets/rinkeby/0xa4d67c48c155b0cc3d9a36355fbbc0e80345ee78/" + currentSystemId}
          >View System On OpenSea</Button>
        ) : (
          ""
        )}
      </div>
    </div>
  );
}
export default App;
