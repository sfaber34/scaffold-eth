// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import 'hardhat/console.sol';

contract SystemData {

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  function createSystem(
      string memory name,
      uint16 distToSol,
      uint8 stRadius,
      string memory stColor,
      uint8[] memory plRadius,
      string[] memory plColor 
    ) public {
    
    uint16[] memory orbDist = new uint16[] (plRadius.length);
    uint16 plDiamSum;
    uint16 orbGap;

    systems.push(Structs.System({
      name: name,
      distToSol: distToSol,
      radius: stRadius,
      color: stColor,
      owner: msg.sender,
      planets: new uint256[] (0)
    }));

    for (uint i=0; i<plRadius.length; i++) {
      plDiamSum += plRadius[i] * 2;
    }
    
    orbGap = (500 - stRadius - plDiamSum) / uint16(plRadius.length);
    
    orbDist[0] = stRadius + plRadius[0] + orbGap;
    for (uint i=1; i<plRadius.length; i++) {
      orbDist[i] = orbDist[i-1] + plRadius[i] * 2 + orbGap;
    }

    for(uint8 i=0; i<plRadius.length; i++){
      planets.push(Structs.Planet({
        radius: plRadius[i],
        orbDist: orbDist[i],
        color: plColor[i]
      }));
      
      systems[systems.length-1].planets.push(planets.length-1); 
    }
  }

  function getSystem(uint256 systemId) external view returns(Structs.System memory returnSystem){
    returnSystem = systems[systemId];

    return returnSystem;
  }
  
  function getPlanet(uint256 systemId) external view returns(Structs.Planet[] memory returnPlanets){
    returnPlanets = new Structs.Planet[] (systems[systemId].planets.length);
    uint256[] memory returnPlanetsId = systems[systemId].planets;

    for(uint256 i=0; i<systems[systemId].planets.length; i++){
      returnPlanets[i] = planets[returnPlanetsId[i]];
    }
    
    return returnPlanets;
  }
}

