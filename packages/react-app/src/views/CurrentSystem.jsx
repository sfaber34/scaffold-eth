import React, { useEffect, useState } from "react";
import { Card, List, Spin } from "antd";
import { Address } from "../components";

function CurrentSystem({ yourCollectibles, id, blockExplorer, totalSupply, DEBUG }) {
  const [currentSystem, setCurrentSystem] = useState();

  useEffect(() => {
    const updateCurrentSystem = async () => {
        if (yourCollectibles && id >= 0) {
            const collectible = yourCollectibles.find(c => c.id === id);
        }
    };
    updateCurrentSystem();
  }, [id]);

  return (
    <div style={{ width: "auto", margin: "auto", paddingBottom: 25, minHeight: 800 }}>
      <img src={currentSystem.image} alt={currentSystem.name} />
    </div>
  );
}

export default CurrentSystem;
