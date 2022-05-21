// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './ToColor.sol';

//START HERE: Copy

contract SystemData {

  using ToColor for bytes3;

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  function createSystem() public {

    bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
    uint16 nPlanets = uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % 3 + 2;
    
    systems.push(Structs.System({
      name: 'TOI-178',
      radius: uint16(bytes2(predictableRandom[2]) | ( bytes2(predictableRandom[3]) >> 8 )) % 120 + 30,
      color: 'ffd5b3',
      owner: msg.sender,
      planets: new uint256[] (0)
    }));


    uint16 plDiamSum;
    uint16 orbDeadSpace;
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint16[] memory plOrbDist = new uint16[] (nPlanets);
    for (uint i=0; i<nPlanets; i++){
      plRadii[i] = uint16(bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 )) % 35 + 5;
      // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
      plDiamSum += plRadii[i] * 2;
    }

    // Handles when star radius + sum of planet diameters won't fit in SVG
    if (plDiamSum + systems[systems.length-1].radius > 500){
      uint16 diamOverflow = plDiamSum + systems[systems.length-1].radius - 500; // How many extra pixels need to be removed
      
      plDiamSum = 0;
      for (uint i=0; i<nPlanets; i++) {
        // Reduce planet radii by common factor. + 5 so that planets with reduced radii aren't touching
        plRadii[i] = plRadii[i] - (diamOverflow / 2 / nPlanets + 5);
        // Recalculate new planet diameters sum using reduced planet radii
        plDiamSum += plRadii[i] * 2;
      }
      
    }

    // The number of pixels to add between planet orbit distance to spread them out evenly.
    orbDeadSpace = (500 - systems[systems.length-1].radius - plDiamSum) / uint16(nPlanets);
    
    plOrbDist[0] = systems[systems.length-1].radius + plRadii[0] + orbDeadSpace;
    for (uint i=1; i<nPlanets; i++) {
      plOrbDist[i] = plOrbDist[i-1] + plRadii[i] * 2 + orbDeadSpace;
    }

    for (uint i=0; i<nPlanets; i++){
      bytes3 colorBytesA = bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 ) | ( bytes3(predictableRandom[i+2]) >> 16 );
      bytes3 colorBytesB = bytes2(predictableRandom[i+3]) | ( bytes2(predictableRandom[i+4]) >> 8 ) | ( bytes3(predictableRandom[i+5]) >> 16 );
      bytes3 colorBytesC = bytes2(predictableRandom[i+6]) | ( bytes2(predictableRandom[i+7]) >> 8 ) | ( bytes3(predictableRandom[i+8]) >> 16 );

      planets.push(Structs.Planet({
        radius: plRadii[i],
        orbDist: plOrbDist[i],
        colorA: colorBytesA.toColor(),
        colorB: colorBytesB.toColor(),
        colorC: colorBytesC.toColor()
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

