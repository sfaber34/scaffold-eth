// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './SystemName.sol';
import './Uint2Str.sol';
import './ToColor.sol';

// import "hardhat/console.sol";

// TODO: Add additional attributes we might want for game... galactic coordinates, planet density, planet mass, resources?
// TODO: Look at <feImage> for star background
// TODO: Fix fast spinning planet bug in home view (might be the gausian blur in svg tags?)
// TODO: Figure out the habitable zone range
// TODO: Try to make rocky planets look more different
// TODO: Fix URI attributes
// TODO: Look at planet layout/scaling again... Slightly upping the max gas planet size seems to make things too crowded
// TODO: Make water world base lightness = 55%


library SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;
  using SystemName for uint256;

  function generateSystemData(uint256 id) external pure returns (Structs.System memory system, Structs.Planet[] memory) {
    system.name = id.generateSystemName();

    (uint16 radius, uint16 hue, string memory category) = getStarAttributes(id);
    system.radius = radius;
    system.hue = hue;
    system.category = category;

    (uint16[] memory plRadii, 
    uint16[] memory plOrbDist, 
    uint8[] memory plCategory) = getPlanetRadiiOrbitsTypes(id, system.radius);
    
    Structs.Planet[] memory planets = new Structs.Planet[] (plRadii.length);

    for (uint i=0; i<plRadii.length; i++) {
      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].category = plCategory[i];

      (uint16 turbScale, uint16[5] memory plHues) = getPlanetHuesTurbScale(id, i, plCategory[i]);

      planets[i].turbScale = turbScale;
      planets[i].hueA = plHues[0];
      planets[i].hueB = plHues[1];
      planets[i].hueC = plHues[2];
      planets[i].hueD = plHues[3];
      planets[i].hueE = plHues[4];
    }

    return (system, planets);
  }

  function getStarAttributes(uint256 id) internal pure returns (uint16 radius, uint16 hue, string memory category) {
    bytes32 seed = bytes32(id);
    
    radius = uint16(bytes2(seed[6]) | (bytes2(seed[7]) >> 8)) % 71 + 20;

    if (radius < 41) {
      hue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 41 + 180;
      category = 'blue dwarf';
    } else if (radius > 69) {
      hue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 21;
      category = 'red giant';
    } else {
      hue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 26 + 30;
      category = 'main category';
    }

    return (radius, hue, category);
  }

  function getPlanetRadiiOrbitsTypes(uint256 id, uint16 starRadius) internal pure returns (uint16[] memory, uint16[] memory, uint8[] memory) {
    bytes32 seed = bytes32(id);

    uint16 nPlanets = uint16(bytes2(seed[0]) | ( bytes2(seed[1]) >> 8 )) % 4 + 2;
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint16[] memory plOrbDist = new uint16[] (nPlanets);
    uint8[] memory plCategory = new uint8[] (nPlanets);

    uint16 plDiamSum;     

    for (uint i=0; i<nPlanets; i++) {
      // plRadii[] pushed to Planets struct below but need to do checks on layout first
      plRadii[i] = uint16(bytes2(seed[i]) | ( bytes2(seed[31-i]) >> 8 )) % 26 + 10;
      // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
      plDiamSum += plRadii[i] * 2;
    }

    // Handles when star radius + sum of planet diameters won't fit in SVG. Probaby a dumb way of doing this
    if (plDiamSum + starRadius > 480) { // > 480 instead of > 500 to exclude possibility of planets touching
      uint16 diamOverflow = plDiamSum + starRadius - 500; // How many extra pixels need to be removed
      
      plDiamSum = 0;
      for (uint i=0; i<nPlanets; i++) {
        // Reduce planet radii by common factor.
        plRadii[i] = plRadii[i] - (diamOverflow / 2 / nPlanets + 5);
        // Recalculate new planet diameters sum using reduced planet radii
        plDiamSum += plRadii[i] * 2;
      }
      
    }
    
    // The number of pixels to add between planet orbit distance to spread them out evenly.
    uint16 orbDeadSpace = (500 - starRadius - plDiamSum - 10) / uint16(nPlanets);
    
    plOrbDist[0] = starRadius + plRadii[0] + orbDeadSpace;
    for (uint i=1; i<nPlanets; i++) {
      plOrbDist[i] = plOrbDist[i-1] + plRadii[i] * 2 + orbDeadSpace;
    }

    for (uint i=0; i<nPlanets; i++) {
      if (plRadii[i] > 19) {
        plCategory[i] = 0;
      } else {
        if (plOrbDist[i] < 300) {
          plCategory[i] = 2;
        } else {
          plCategory[i] = 1;
        }
      }
    }

    return (plRadii, plOrbDist, plCategory);
  }

  function getPlanetHuesTurbScale(uint256 id, uint256 index, uint8 plCategory) internal pure returns (uint16 turbScale, uint16[5] memory plHues) {
    bytes32 seed = bytes32(id);

    // Gas giant
    if (plCategory == 0) {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 8 + 7;
      plHues[0] = uint16(bytes2(seed[index])) % 360;
      plHues[1] = uint16(bytes2(seed[index+7])) % 360;
      plHues[2] = uint16(bytes2(seed[index+14])) % 360;
      plHues[3] = uint16(bytes2(seed[index+19])) % 360;
      plHues[4] = uint16(bytes2(seed[index+25])) % 360;
    }
    // Rocky planet 
    else if (plCategory == 1) {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 21 + 20;
      plHues[0] = uint16(bytes2(seed[index])) % 121;
      plHues[1] = plHues[0] + uint16(bytes2(seed[index+7])) % 11;
      plHues[2] = uint16(bytes2(seed[index+14])) % 131;
      plHues[3] = uint16(bytes2(seed[index+19])) % 131;
      plHues[4] = uint16(bytes2(seed[index+25])) % 131;
    }
    // Water world 
    else {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 23 + 18;
      plHues[0] = uint16(bytes2(seed[index])) % 51 + 170;
      plHues[1] = uint16(bytes2(seed[index+7])) % 51;
      plHues[2] = uint16(bytes2(seed[index+14])) % 51;
      plHues[3] = uint16(bytes2(seed[index+19])) % 71 + 70;
      plHues[4] = uint16(bytes2(seed[index+25])) % 71 + 70;
    }

    return (turbScale, plHues);
  } 

}