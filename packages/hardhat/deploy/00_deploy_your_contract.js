// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const trigonometry = await deploy("Trigonometry", {
    from: deployer,
    log: true,
  });

  const structs = await deploy("Structs", {
    from: deployer,
    log: true,
  });

  const systemData = await deploy("SystemData", {
    from: deployer,
    log: true,
    libraries: {
      Structs: structs.address
    }
  });

  const calculateLayout = await deploy("CalculateLayout", {
    from: deployer,
    log: true
  });

  const returnSvg = await deploy("ReturnSvg", {
    from: deployer,
    log: true,
    libraries: {
      Trigonometry: trigonometry.address,
      Structs: structs.address
    }
  });

  await deploy("YourCollectible", {
    from: deployer,
    log: true,
    args: [systemData.address],
    libraries: {
      ReturnSvg: returnSvg.address,
      Trigonometry: trigonometry.address
    }
  });
  

  // Verify your contracts with Etherscan
  // You don't want to verify on localhost
  if (chainId !== localChainId) {
    await run("verify:verify", {
      address: YourCollectible.address,
      contract: "contracts/YourCollectible.sol:YourCollectible",
      contractArguments: [],
    });
  }
};
module.exports.tags = ["YourCollectible"];
