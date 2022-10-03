// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract ReturnPlanetResources {

  function returnPlanetResources(bytes32 randomish, uint256 index, uint8 plCategory) public view returns (uint8[3] memory, uint8[3] memory) {

    uint8[3] memory resources;
    uint8[3] memory abundance;

    resources[0] = 1;
    resources[1] = 1;
    resources[2] = 1;

    console.log("plCategory: %s", plCategory);
    console.log("%s: %s", resources[0], abundance[0]);
    console.log("%s: %s", resources[1], abundance[1]);
    console.log("%s: %s", resources[2], abundance[2]);
    return (resources, abundance);
  }

  function resourceCodeToName(uint8 resourceCode) public pure returns (string memory) {

    string[18] memory resourceList = [
      '', 'Undiscovered', 'Hydrogen', 'Ammonia', 'Methane', 
      'Aluminium', 'Iron', 'Nickel', 'Copper',
      'Silicon', 'Gold', 'Titanium', 'Lithium',
      'Cobalt', 'Platinum', 'Chromium', 'Terbium',
      'Selenium'
    ];

    return resourceList[resourceCode];
  }

}