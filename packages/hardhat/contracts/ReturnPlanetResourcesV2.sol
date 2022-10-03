// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract ReturnPlanetResourcesV2 {

  function returnPlanetResources(bytes32 randomish, uint256 index, uint8 plCategory) public view returns (uint8[3] memory, uint8[3] memory) {
    bytes32 randomishC = keccak256(abi.encodePacked( randomish, index, plCategory));

    uint8[3] memory prelimResources;
    uint8[3] memory resources;
    uint8[3] memory abundance;
    bool unique;
    uint8 k = 1;  

    if (plCategory == 0) {
      resources = [2, 3, 4];
      abundance[0] = uint8(bytes1(randomishC[3])) % 100 + 1;
      abundance[1] = uint8(bytes1(randomishC[4])) % 100 + 1;
      abundance[2] = uint8(bytes1(randomishC[5])) % 100 + 1;
    } else {
      for (uint i=0; i<3;) {
        uint8 picker = uint8(bytes1(randomishC[i]));
        
        if (picker <= 49) {
          prelimResources[i] = 5; // Aluminum
        }
        else if (picker > 49 && picker <= 94) {
          prelimResources[i] = 6; // Iron
        }
        else if (picker > 94 && picker <= 131) {
          prelimResources[i] = 7; // Nickel
        }
        else if (picker > 131 && picker <= 164) {
          prelimResources[i] = 8; // Copper
        }
        else if (picker > 164 && picker <= 191) {
          prelimResources[i] = 9; // Silicon
        }
        else if (picker > 191 && picker <= 206) {
          prelimResources[i] = 10; // Gold
        }
        else if (picker > 206 && picker <= 219) {
          prelimResources[i] = 11; // Titanium
        }
        else if (picker > 219 && picker <= 230) {
          prelimResources[i] = 12; // Lithium
        }
        else if (picker > 230 && picker <= 239) {
          prelimResources[i] = 13; // Cobalt
        }
        else if (picker > 239 && picker <= 246) {
          prelimResources[i] = 14; // Platinum
        }
        else if (picker > 246 && picker <= 251) {
          prelimResources[i] = 15; // Chromium
        }
        else if (picker > 251 && picker <= 254) {
          prelimResources[i] = 16; // Terbium
        }
        else if (picker == 255) {
          prelimResources[i] = 17; // Selenium
        }

        unchecked { ++ i; }
      }

      resources[0] = prelimResources[0];
      abundance[0] = uint8(bytes1(randomishC[3])) % 100 + 1;

      for (uint i=1; i<3;) {
        unique = true;

        for (uint j=0; j<i;) {
          if (prelimResources[i] == prelimResources[j]) {
            unique = false;
            break;
          }

          unchecked { ++ j; }
        }

        if (unique) {
          resources[k] = prelimResources[i];
          abundance[k] = uint8(bytes1(randomishC[3+k])) % 100 + 1;

          unchecked { ++ k; }
        }

        unchecked { ++ i; }
      }
    }
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