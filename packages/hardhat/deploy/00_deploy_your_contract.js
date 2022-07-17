// deploy/00_deploy_your_contract.js

const { ethers } = require("hardhat");

const localChainId = "31337";

// const sleep = (ms) =>
//   new Promise((r) =>
//     setTimeout(() => {
//       console.log(`waited for ${(ms / 1000).toFixed(3)} seconds`);
//       r();
//     }, ms)
//   );

module.exports = async ({ getNamedAccounts, deployments, getChainId }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = await getChainId();

  const trigonometry = await deploy("Trigonometry", {
    from: deployer,
    log: true,
    waitConfirmations: 5,
  });

  const structs = await deploy("Structs", {
    from: deployer,
    log: true,
  });

  const populateSystemLayoutStructs = await deploy("PopulateSystemLayoutStructs", {
    from: deployer,
    log: true,
    libraries: {
      Structs: structs.address
    }
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
      populateSystemLayoutStructs.address,
      returnSystemSvg.address,
    ],
    libraries: {
      Structs: structs.address,
      Trigonometry: trigonometry.address,
    }
  });

  const yourCollectible = await ethers.getContract("YourCollectible", deployer);
  await yourCollectible.transferOwnership("0x38c772B96D73733F425746bd368B4B4435A37967"); 


  // Verify from the command line by running `yarn verify`

  // You can also Verify your contracts with Etherscan here...
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
