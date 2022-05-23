// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './ToColor.sol';
import './Uint2Str.sol';

//Note: Not sure that the method for planet colors is as random as could be (the way i'm doing byte positions)

contract SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;

  string[20] internal sectors = [
    'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
    'Xi', 'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
    'Mantis', 'Archer', 'Kappa', 'Ares', 'Icarus', 'Gamma', 
    'Tycho',  'Vesta',  'Zephyr'
  ]; 

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  function createSystem() public {

    bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp ));
    // Pick number of planets and system sector
    uint16 nPlanets = uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % 5 + 2;
    string memory thisSector = sectors[uint16(bytes2(predictableRandom[2]) | ( bytes2(predictableRandom[3]) >> 8 )) % 19];
    
    // Index the system sector based on how many sister systems have been minted
    uint16 sectorI = 1;
    for (uint i=0; i<systems.length; i++) {
      if (keccak256(abi.encodePacked(systems[i].sector)) == keccak256(abi.encodePacked(thisSector))){
        sectorI ++;
      }
    }
    
    // Add the system with star radius between 20 to 90 px and a yellow/orange hue
    systems.push(Structs.System({
      sector: thisSector,
      sectorI: sectorI,
      radius: uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[7]) >> 8 )) % 70 + 20,
      colorH: uint16(bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 )) % 40 + 5,
      owner: msg.sender,
      planets: new uint256[] (0)
    }));

    uint16 plDiamSum;
    uint16 orbDeadSpace; 
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint16[] memory plOrbDist = new uint16[] (nPlanets);
    for (uint i=0; i<nPlanets; i++){
      // plRadii[] pushed to Planets struct below but need to do checks on layout first
      plRadii[i] = uint16(bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 )) % 23 + 5;
      // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
      plDiamSum += plRadii[i] * 2;
    }

    // Handles when star radius + sum of planet diameters won't fit in SVG. Probaby a dumb way of doing this
    if (plDiamSum + systems[systems.length-1].radius > 480){ // > 480 instead of > 500 to exclude possibility of planets touching
      uint16 diamOverflow = plDiamSum + systems[systems.length-1].radius - 500; // How many extra pixels need to be removed
      
      plDiamSum = 0;
      for (uint i=0; i<nPlanets; i++) {
        // Reduce planet radii by common factor.
        plRadii[i] = plRadii[i] - (diamOverflow / 2 / nPlanets + 5);
        // Recalculate new planet diameters sum using reduced planet radii
        plDiamSum += plRadii[i] * 2;
      }
      
    }
    
    // The number of pixels to add between planet orbit distance to spread them out evenly.
    orbDeadSpace = (500 - systems[systems.length-1].radius - plDiamSum - 10) / uint16(nPlanets);
    
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

      // Make the star a blue dwarf (hue:200-240) if any planet radii is within 10 px of star radius
      for (uint i=0; i<nPlanets; i++){
        if (plRadii[i] > systems[systems.length-1].radius - 10){
          systems[systems.length-1].colorH = uint16(bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 )) % 40 + 200;
        }
      }
      // Keep track of planet ids to link them to systems
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

