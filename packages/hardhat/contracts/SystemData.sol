// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './SystemName.sol';
import './Uint2Str.sol';
import './ToColor.sol';

// import "hardhat/console.sol";

library SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;
  using SystemName for uint256;

  function createSystem(uint256 id) external pure returns (Structs.System memory, Structs.Planet[] memory) {

    bytes32 seed = bytes32(id);

    uint16 nPlanets = uint16(bytes2(seed[0]) | ( bytes2(seed[1]) >> 8 )) % 5 + 2;

    Structs.System memory system;
    Structs.Planet[] memory planets = new Structs.Planet[] (nPlanets);

    system.name = id.systemName();
    system.radius = uint16(bytes2(seed[6]) | ( bytes2(seed[7]) >> 8 )) % 70 + 20;
    system.colorH = uint16(bytes2(seed[30]) | ( bytes2(seed[31]) >> 8 )) % 60;
    system.sequence = 'main sequence';

    uint16 plDiamSum;
    uint16 orbDeadSpace; 
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint16[] memory plOrbDist = new uint16[] (nPlanets);
    for (uint i=0; i<nPlanets; i++) {
      // plRadii[] pushed to Planets struct below but need to do checks on layout first
      plRadii[i] = uint16(bytes2(seed[i]) | ( bytes2(seed[i+1]) >> 8 )) % 23 + 5;
      // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
      plDiamSum += plRadii[i] * 2;
    }

    // Handles when star radius + sum of planet diameters won't fit in SVG. Probaby a dumb way of doing this
    if (plDiamSum + system.radius > 480) { // > 480 instead of > 500 to exclude possibility of planets touching
      uint16 diamOverflow = plDiamSum + system.radius - 500; // How many extra pixels need to be removed
      
      plDiamSum = 0;
      for (uint i=0; i<nPlanets; i++) {
        // Reduce planet radii by common factor.
        plRadii[i] = plRadii[i] - (diamOverflow / 2 / nPlanets + 5);
        // Recalculate new planet diameters sum using reduced planet radii
        plDiamSum += plRadii[i] * 2;
      }
      
    }
    
    // The number of pixels to add between planet orbit distance to spread them out evenly.
    orbDeadSpace = (500 - system.radius - plDiamSum - 10) / uint16(nPlanets);
    
    plOrbDist[0] = system.radius + plRadii[0] + orbDeadSpace;
    for (uint i=1; i<nPlanets; i++) {
      plOrbDist[i] = plOrbDist[i-1] + plRadii[i] * 2 + orbDeadSpace;
    }

    for (uint i=0; i<nPlanets; i++) {

      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].colorA = ( bytes2(seed[i]) | ( bytes2(seed[i+1]) >> 8 ) | ( bytes3(seed[i+2]) >> 16 ) ).toColor();
      planets[i].colorB = ( bytes2(seed[i+9]) | ( bytes2(seed[i+10]) >> 8 ) | ( bytes3(seed[i+11]) >> 16 ) ).toColor();
      planets[i].colorC = ( bytes2(seed[i+19]) | ( bytes2(seed[i+20]) >> 8 ) | ( bytes3(seed[i+21]) >> 16 ) ).toColor();
      planets[i].colorD = ( bytes2(seed[i+26]) | ( bytes2(seed[20-i]) >> 8 ) | ( bytes3(seed[i+9]) >> 16 ) ).toColor();

      // Make the star a blue dwarf (hue:200-240) if any planet radii is within 10 px of star radius
      for (uint i=0; i<nPlanets; i++){
        if (plRadii[i] > system.radius - 10){
          system.colorH = uint16(bytes2(seed[30]) | ( bytes2(seed[31]) >> 8 )) % 105 + 150;
          system.sequence = 'blue dwarf';
        }
      }
    }

    return (system, planets);
  }
  
}

