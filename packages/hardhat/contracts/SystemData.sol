// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';

contract SystemData {

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  function createSystem(
      string memory name,
      uint16 distToSol,
      uint8 stRadius,
      string memory stColor,
      uint8[] memory plRadius,
      string[] memory plColorA,
      string[] memory plColorB,
      string[] memory plColorC
    ) public {
    
    systems.push(Structs.System({
      name: name,
      distToSol: distToSol,
      radius: stRadius,
      color: stColor,
      owner: msg.sender,
      planets: new uint256[] (0)
    }));

    // Planet orbit radial distance calculated here. Makes planets ~ evenly distributed.
    // Probably better to do this in returnSvg() to avoid passing extra data but...
    uint16[] memory orbDist = new uint16[] (plRadius.length);
    uint16 plDiamSum;
    uint16 orbDeadSpace;

    // Calculate how many pixels all planets would span if stacked from the edge of the star outward
    for (uint i=0; i<plRadius.length; i++) {
      plDiamSum += plRadius[i] * 2;
    }
    // The number of pixels to add between planet orbit distance to spread them out evenly.
    orbDeadSpace = (500 - stRadius - plDiamSum) / uint16(plRadius.length);
    
    orbDist[0] = stRadius + plRadius[0] + orbDeadSpace;
    for (uint i=1; i<plRadius.length; i++) {
      orbDist[i] = orbDist[i-1] + plRadius[i] * 2 + orbDeadSpace;
    }

    for(uint8 i=0; i<plRadius.length; i++){
      planets.push(Structs.Planet({
        radius: plRadius[i],
        orbDist: orbDist[i],
        colorA: plColorA[i],
        colorB: plColorB[i],
        colorC: plColorC[i]
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

