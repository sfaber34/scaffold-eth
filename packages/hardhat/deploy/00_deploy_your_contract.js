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

  const systemName = await deploy("SystemName", {
    from: deployer,
    log: true,
  });

  const populateSystemLayoutStructs = await deploy("PopulateSystemLayoutStructs", {
    from: deployer,
    log: true,
    args: [
      structs.address,
      systemName.address
    ],
  });

  const returnSystemSvg = await deploy("ReturnSystemSvg", {
    from: deployer,
    log: true,
    libraries: {
      Structs: structs.address,
      Trigonometry: trigonometry.address,
    }
  });

  // const test = await deploy("Test", {
  //   from: deployer,
  //   log: true,
  //   libraries: {
  //     Structs: structs.address
  //   }
  // });

  await deploy("YourCollectible", {
    from: deployer,
    log: true,
    args: [
      structs.address,
      populateSystemLayoutStructs.address,
      systemName.address,
      returnSystemSvg.address,
    ],
    libraries: {
      Structs: structs.address,
      Trigonometry: trigonometry.address,
    }
  });
  

  // Verify your contracts with Etherscan
  // You don't want to verify on localhost
  // if (chainId !== localChainId) {
  //   await run("verify:verify", {
  //     address: YourCollectible.address,
  //     contract: "contracts/YourCollectible.sol:YourCollectible",
  //     contractArguments: [],
  //   });
  // }
};
module.exports.tags = ["YourCollectible"];
