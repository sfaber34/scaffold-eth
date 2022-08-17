// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';
import "hardhat/console.sol";

interface IPopulateSystemLayoutStructsB {
  
  function populateSystemLayoutStructs(
    bytes32 randomish
  ) external view returns (
    Structs.System memory system, Structs.Planet[] memory
  );
  
}

contract Test {
  
  // uint8[5] public selectedResourcesPub;
  string[3] public selectedResourcesPub;
  uint8[3] public resourcesPub;
  uint8[3] public abundancePub;
  uint8 public topResourcePub;

  string[17] public resourceList = [
    '', 'Hydrogen', 'Ammonia', 'Methane', 
    'Aluminium', 'Iron', 'Nickel', 'Copper',
    'Silicon', 'Gold', 'Titanium', 'Lithium',
    'Cobalt', 'Platinum', 'Chromium', 'Terbium',
    'Selenium'
  ];
  

  address public populateSystemLayoutStructsAddress;
  constructor (
    address _populateSystemLayoutStructsAddress
  ) {
    populateSystemLayoutStructsAddress = _populateSystemLayoutStructsAddress;
  } 

  function getTopResources(bytes32 randomish) public returns (uint8) {
    uint8 topResource;

    (Structs.System memory system, Structs.Planet[] memory planets) = IPopulateSystemLayoutStructsB(populateSystemLayoutStructsAddress).populateSystemLayoutStructs(randomish);

    for (uint i=0; i<planets.length;) {
      for (uint j=0; j<3;) {
        console.log(planets[i].resources[j]);
        if(planets[i].resources[j] > topResource) {
          topResource = planets[i].resources[j];
        }
        unchecked { ++ j; }
      }
      unchecked { ++ i; }
    }

    topResourcePub = topResource;
    return topResource;
  }

  function getPlanetResources(bytes32 randomish) public returns (string[3] memory, uint8[3] memory) {
    // string[5] memory selectedResources;
    // string[5] memory resources;
    // string[14] memory resourceList = [
    //   '', 'Aluminium', 'Iron', 'Nickel', 'Copper',
    //   'Silicon', 'Gold', 'Titanium', 'Lithium',
    //   'Cobalt', 'Platinum', 'Chromium', 'Terbium',
    //   'Selenium'
    // ];
    
    uint8[3] memory resources;
    // uint8[5] memory selectedResources;
    string[3] memory selectedResources;
    uint8[3] memory abundance;
    bool unique;
    uint8 k = 1;  

    for (uint i=0; i<3;) {
      uint8 picker = uint8(bytes1(randomish[10+i]));
      
      if (picker <= 39) {
        resources[i] = 1;
      }
      else if (picker > 39 && picker <= 80) {
        resources[i] = 2;
      }
      else if (picker > 80 && picker <= 115) {
        resources[i] = 3;
      }
      else if (picker > 115 && picker <= 146) {
        resources[i] = 4;
      }
      else if (picker > 146 && picker <= 171) {
        resources[i] = 5;
      }
      else if (picker > 171 && picker <= 192) {
        resources[i] = 6;
      }
      else if (picker > 192 && picker <= 211) {
        resources[i] = 7;
      }
      else if (picker > 211 && picker <= 226) {
        resources[i] = 8;
      }
      else if (picker > 226 && picker <= 237) {
        resources[i] = 9;
      }
      else if (picker > 237 && picker <= 246) {
        resources[i] = 10;
      }
      else if (picker > 246 && picker <= 251) {
        resources[i] = 11;
      }
      else if (picker > 251 && picker <= 254) {
        resources[i] = 12;
      }
      else if (picker == 255) {
        resources[i] = 13;
      }

      unchecked { ++ i; }
    }

    selectedResources[0] = resourceList[resources[0]];
    abundance[0] = uint8(bytes1(randomish[13])) % 100 + 1;

    for (uint i=1; i<3;) {
      unique = true;

      for (uint j=0; j<i;) {
        if (resources[i] == resources[j]) {
          unique = false;
          break;
        }

        unchecked { ++ j; }
      }

      if (unique) {
        selectedResources[k] = resourceList[resources[i]];
        abundance[k] = uint8(bytes1(randomish[13+k])) % 100 + 1;

        unchecked { ++ k; }
      }

      unchecked { ++ i; }
    }

    // for (uint i=0; i<k;) {
    //   abundance[i] = uint8(bytes1(randomish[15+i])) % 100 + 1;

    //   unchecked { ++ i; }
    // }

    selectedResourcesPub = selectedResources;
    resourcesPub = resources;
    abundancePub = abundance;

    return (selectedResources, abundance);
  }

}