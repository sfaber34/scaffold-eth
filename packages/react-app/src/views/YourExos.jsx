import React, { useCallback, useEffect, useState, useRef } from "react";
import { StarField, useStarField, StarFieldState, createStarsState } from "starfield-react";
import { Link } from "react-router-dom";
import { Button, Card, List, Menu } from "antd";
import { Address, AddressInput } from "../components";
import { ethers } from "ethers";
import "./YourExos.css";

function YourExos({
  readContracts,
  writeContracts,
  priceToMint,
  yourCollectibles,
  tx,
  mainnetProvider,
  blockExplorer,
  transferToAddresses,
  setTransferToAddresses,
  address,
  currentSystemId,
  warpWhenReady,
  web3Modal,
  loadWeb3Modal,
  setCurrentSystemId,
  setWarpWhenReady
}) {
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
  useEffect(() => {
    const warpToSystem = async systemId => {
      setOpacity(0);
      setHasReachedLimit(false);
      setMoving(true);
      setTimeout(() => setHeight(1), 500);
      const uri = await getSystemURI(systemId, true);
      const jsonManifestString = atob(uri.substring(29));
      const jsonManifest = JSON.parse(jsonManifestString);
      console.log(JSON.stringify(uri));
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
  
  return (
    <div>
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
      <div style={{ margin: "auto", paddingBottom: 25 }}>
        {web3Modal?.cachedProvider ? ( 
        <Button
          key="mintbutton"
          type="primary"
          className={yourCollectibles && yourCollectibles.length == 0 ? 'in-middle' : 'side'}
          style={{ zIndex: 2, display: "block", padding: "0 40px", marginTop: 8 }}
          onClick={async () => {
            setWarpWhenReady(true);
            const priceRightNow = await readContracts.YourCollectible.price();
            try {
              const txCur = await tx(
                writeContracts.YourCollectible.mintItem({ value: priceRightNow, gasLimit: 200000 }),
              ); // 300000
              await txCur.wait();
            } catch (e) {
              console.log("mint failed", e);
            }
          }}
        >
          MINT for Ξ{priceToMint && (+ethers.utils.formatEther(priceToMint)).toFixed(4)}
        </Button>
        ) : (
        <Button 
          key="connectbutton"
          className={yourCollectibles && yourCollectibles.length == 0 ? 'in-middle' : 'side'} 
          style={{ zIndex: 2, display: "block", padding: "0 40px", marginTop: 8 }}
          type="primary"
          onClick={loadWeb3Modal}>
          Connect Wallet
        </Button>
      )}
        {yourCollectibles && yourCollectibles.length > 0
          ?
          <Menu
            style={{ textAlign: "left", position: "absolute", zIndex: 2, backgroundColor: "#00000000" }}
            mode="vertical"
          >
            <Menu.ItemGroup
              selectedKeys={[currentSystemId]}
              title="Your Exos">
              {yourCollectibles.map(c => (
                <Menu.Item
                  key={c.id.toNumber()}
                  onClick={() => {
                    setCurrentSystemId(c.id.toNumber());
                  }}
                >
                  {c.name}
                </Menu.Item>
              ))}
            </Menu.ItemGroup>

          </Menu>
          : ""}
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

export default YourExos;
