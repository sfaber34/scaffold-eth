// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './Uint2Str.sol';
import './ToColor.sol';

// import "hardhat/console.sol";

// TODO: Add additional attributes we might want for game... galactic coordinates, planet density, planet mass, resources?
// TODO: Look at <feImage> for star background
// TODO: Fix fast spinning planet bug in home view (might be the gausian blur in svg tags?)
// TODO: Figure out the habitable zone range
// TODO: Try to make rocky planets look more different
// TODO: Fix URI attributes
// TODO: Make system.category int (and) probably remove from system struct


contract SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;

  function getStarRadius(uint256 id) external pure returns (uint16 starRadius) {
    bytes32 seed = bytes32(id);
    
    starRadius = uint16(bytes2(seed[6]) | (bytes2(seed[7]) >> 8)) % 71 + 20;
    // starRadius = 90;

    return starRadius;
  }


  function getStarCategory(uint16 starRadius) external pure returns (string memory starCategory) {

    if (starRadius < 41) {
      starCategory = 'blue dwarf';
    } 
    else if (starRadius > 69) {
      starCategory = 'red giant';
    } 
    else {
      starCategory = 'main category';
    }

    return starCategory;
  }


  function getStarHue(uint256 id, uint16 starRadius) external pure returns (uint16 starHue) {
    bytes32 seed = bytes32(id);

    // Blue Dwaft
    if (starRadius < 41) {
      starHue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 41 + 180;
    }
    // Red Giant 
    else if (starRadius > 69) {
      starHue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 21;
    }
    // Main Sequence 
    else {
      starHue = uint16(bytes2(seed[30]) | (bytes2(seed[31]) >> 8)) % 26 + 30;
    }

    return starHue;
  }


  function getPlanetRadii(uint256 id, uint16 nPlanets) external pure returns (uint16[] memory) {
    bytes32 seed = bytes32(id);

    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint8 nNonGas;
    
    for (uint i=0; i<nPlanets; i++) {
      plRadii[i] = uint16(bytes2(seed[i]) | ( bytes2(seed[31-i]) >> 8 )) % 24 + 10;
      // plRadii[i] = 33;

      // Keep track of n non-gas planets. Want at least 1 planet that players can land on
      if (plRadii[i] < 20) {
        nNonGas++;
      }
    }

    // If all planets are gas, make the one closest to star a rocky (or possibly) earth-like world
    if (nNonGas == 0) {
      plRadii[0] = uint16(bytes2(seed[0]) | ( bytes2(seed[31]) >> 8 )) % 10 + 10;
    }

    return plRadii;
  }


  function getPlanetOrbitDistance(uint16 starRadius, uint16[] memory plRadii) external pure returns (uint16[] memory) {

    uint16[] memory plOrbDist = new uint16[] (plRadii.length);

    uint16 plDiamSum;  

    // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
    for (uint i=0; i<plRadii.length; i++) {
      plDiamSum += plRadii[i] * 2;
    }

    // The number of pixels to add between each planet to spread them out evenly.
    uint16 orbDeadSpace = (500 - starRadius - plDiamSum) / uint16(plRadii.length);
    
    plOrbDist[0] = starRadius + plRadii[0] + orbDeadSpace;

    for (uint i=1; i<plRadii.length; i++) {
      plOrbDist[i] = plOrbDist[i-1] + plRadii[i-1] + plRadii[i] + orbDeadSpace;
    }

    return plOrbDist;
  }


  function getPlanetCategories(uint16[] memory plRadii, uint16[] memory plOrbDist) external pure returns (uint8[] memory) {

    uint8[] memory plCategory = new uint8[] (plRadii.length);

    for (uint i=0; i<plRadii.length; i++) {
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

    return plCategory;
  }


  function getNPlanets(uint256 id) external pure returns (uint16 nPlanets) {
    bytes32 seed = bytes32(id);

    nPlanets = uint16(bytes2(seed[0]) | ( bytes2(seed[1]) >> 8 )) % 4 + 2;
    // nPlanets = 5;

    return nPlanets;
  }


  function getPlanetHues(uint256 id, uint256 index, uint8 plCategory) external pure returns (uint16[5] memory plHues) {
    bytes32 seed = bytes32(id);

    // Gas giant
    if (plCategory == 0) {
      plHues[0] = uint16(bytes2(seed[index])) % 360;
      plHues[1] = uint16(bytes2(seed[index+7])) % 360;
      plHues[2] = uint16(bytes2(seed[index+14])) % 360;
      plHues[3] = uint16(bytes2(seed[index+19])) % 360;
      plHues[4] = uint16(bytes2(seed[index+25])) % 360;
    }
    // Rocky planet 
    else if (plCategory == 1) {
      plHues[0] = uint16(bytes2(seed[index])) % 121;
      plHues[1] = plHues[0] + uint16(bytes2(seed[index+7])) % 11;
      plHues[2] = uint16(bytes2(seed[index+14])) % 131;
      plHues[3] = uint16(bytes2(seed[index+19])) % 131;
      plHues[4] = uint16(bytes2(seed[index+25])) % 131;
    }
    // Water world 
    else {
      plHues[0] = uint16(bytes2(seed[index])) % 36 + 170;
      plHues[1] = uint16(bytes2(seed[index+7])) % 51;
      plHues[2] = uint16(bytes2(seed[index+14])) % 51;
      plHues[3] = uint16(bytes2(seed[index+19])) % 71 + 70;
      plHues[4] = uint16(bytes2(seed[index+25])) % 71 + 70;
    }

    return plHues;
  }

  function getPlanetTurbScale(uint256 id, uint256 index, uint8 plCategory) external pure returns (uint16 turbScale) {
    bytes32 seed = bytes32(id);

    // Gas giant
    if (plCategory == 0) {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 8 + 7;
    }
    // Rocky planet 
    else if (plCategory == 1) {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 21 + 20;
    }
    // Water world 
    else {
      turbScale = uint16(bytes2(seed[index+6]) | ( bytes2(seed[index+16]) >> 8 )) % 23 + 18;
    }

    return turbScale;
  }  

}