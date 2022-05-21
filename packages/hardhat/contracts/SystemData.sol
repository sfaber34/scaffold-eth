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
    // uint16 nPlanets = 5;
    
    systems.push(Structs.System({
      name: 'TOI-178',
      distToSol: 112,
      radius: uint16(bytes2(predictableRandom[2]) | ( bytes2(predictableRandom[3]) >> 8 )) % 120 + 30,
      color: 'ffd5b3',
      owner: msg.sender,
      planets: new uint256[] (0)
    }));

    // Planet orbit radial distance calculated here. Makes planets ~ evenly distributed.
    // Probably better to do this in returnSvg() to avoid passing extra data but...
    // uint16[] memory orbDist = new uint16[] (plRadius.length);
    uint16 plDiamSum;
    uint16 orbDeadSpace;

    for (uint i=0; i<nPlanets; i++){
      bytes3 colorBytesA = bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 ) | ( bytes3(predictableRandom[i+2]) >> 16 );
      bytes3 colorBytesB = bytes2(predictableRandom[i+3]) | ( bytes2(predictableRandom[i+4]) >> 8 ) | ( bytes3(predictableRandom[i+5]) >> 16 );
      bytes3 colorBytesC = bytes2(predictableRandom[i+6]) | ( bytes2(predictableRandom[i+7]) >> 8 ) | ( bytes3(predictableRandom[i+8]) >> 16 );

      planets.push(Structs.Planet({
        radius: uint16(bytes2(predictableRandom[i+4]) | ( bytes2(predictableRandom[i+5]) >> 8 )) % 35 + 5,
        orbDist: 250,
        colorA: colorBytesA.toColor(),
        colorB: colorBytesB.toColor(),
        colorC: colorBytesC.toColor()
      }));

      plDiamSum += planets[i].radius * 2;
      
      systems[systems.length-1].planets.push(planets.length-1); 
    }

    // // Handles when star radius + sum of planet radii won't fit in SVG
    // if (plDiamSum + systems.radius > 500){
    //   uint16 diamOverflow = plDiamSum + systems.radius - 500; // How many extra pixels need to be removed
      
    //   plDiamSum = 0;
    //   for (uint i=0; i<nPlanets; i++) {
    //     // Reduce planet radii by common factor. + 5 so that planets with reduced radii aren't touching
    //     planets[i].radius = planets[i].radius - (diamOverflow / 2 / nPlanets + 5);
    //     // Recalculate new planet diameters sum using reduced planet radii
    //     plDiamSum += planets[i].radius * 2;
    //   }
      
    // }

    // // The number of pixels to add between planet orbit distance to spread them out evenly.
    // orbDeadSpace = (500 - systems.radius - plDiamSum) / uint16(nPlanets);
    
    // planets[0].orbDist = systems.radius + planets[0].radius + orbDeadSpace;
    // for (uint i=1; i<nPlanets; i++) {
    //   planets[i].orbDist = planets[i-1].orbDist + planets[i].radius * 2 + orbDeadSpace;
    // }

    // Calculate how many pixels all planets would span if stacked from the edge of the star outward
    // for (uint i=0; i<plRadius.length; i++) {
    //   plDiamSum += plRadius[i] * 2;
    // }
    // // The number of pixels to add between planet orbit distance to spread them out evenly.
    // orbDeadSpace = (500 - stRadius - plDiamSum) / uint16(plRadius.length);
    
    // orbDist[0] = stRadius + plRadius[0] + orbDeadSpace;
    // for (uint i=1; i<plRadius.length; i++) {
    //   orbDist[i] = orbDist[i-1] + plRadius[i] * 2 + orbDeadSpace;
    // }

    // for(uint8 i=0; i<plRadius.length; i++){
    //   planets.push(Structs.Planet({
    //     radius: plRadius[i],
    //     orbDist: orbDist[i],
    //     colorA: plColorA[i],
    //     colorB: plColorB[i],
    //     colorC: plColorC[i]
    //   }));
      
    //   systems[systems.length-1].planets.push(planets.length-1); 
    // }
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

