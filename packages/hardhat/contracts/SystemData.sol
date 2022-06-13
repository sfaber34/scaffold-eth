// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './Uint2Str.sol';
import './ToColor.sol';

// import "hardhat/console.sol";

// TODO: Add additional attributes we might want for game... galactic coordinates, planet density, planet mass, resources?
// TODO: Setup multisig
// TODO: Add Galactic coordinates (might need another couple writes to avoid duplicates)
// TODO: Look at <feImage> for star background
// TODO: Fix fast spinning planet bug in home view. Seems to be due to rendering smaller than the 1000 x 1000 native
// TODO: Figure out the habitable zone range
// TODO: Fix URI attributes
// TODO: Make system.category int (and) probably remove from system struct
// TODO: Add craters to rocky worlds
// TODO: See if Structs.sol should be an interface

// interface ISystemName {
//   function generateSystemName(uint256 id) external pure returns (string memory);
// }

contract SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;


  function getSystemCoordinates(bytes32 randomish) external pure returns (uint16[2] memory coordinates) {
    
    coordinates[0] = uint16(bytes2(randomish[6]) | ( bytes2(randomish[7]) >> 8 )) % 10000 + 1;
    coordinates[1] = uint16(bytes2(randomish[8]) | ( bytes2(randomish[9]) >> 8 )) % 10000 + 1; 

    return coordinates;
  }


  function getStarRadius(bytes32 randomish) external pure returns (uint16 starRadius) {
    
    starRadius = uint16(bytes2(0x0000) | ( bytes2(randomish[10]) >> 8 )) % 71 + 20; 
    // starRadius = 90;

    return starRadius;
  }


  function getStarHue(bytes32 randomish, uint16 starRadius) external pure returns (uint16 starHue) {

    // Blue Dwaft
    if (starRadius < 41) {
      starHue = uint16(bytes2(0x0000) | ( bytes2(randomish[11]) >> 8 )) % 41 + 180; 
    }
    // Red Giant 
    else if (starRadius > 69) {
      starHue = uint16(bytes2(0x0000) | ( bytes2(randomish[11]) >> 8 )) % 21;
    }
    // Main Sequence 
    else {
      starHue = uint16(bytes2(0x0000) | ( bytes2(randomish[11]) >> 8 )) % 26 + 30;
    }

    return starHue;
  }


  function getStarCategory(uint16 starRadius) external pure returns (string memory starCategory) {

    if (starRadius < 41) {
      starCategory = 'blue dwarf';
    } 
    else if (starRadius > 69) {
      starCategory = 'red giant';
    } 
    else {
      starCategory = 'main sequence';
    }

    return starCategory;
  }


  function getNPlanets(bytes32 randomish) external pure returns (uint16 nPlanets) {
 
    nPlanets = uint16(bytes2(0x0000) | ( bytes2(randomish[12]) >> 8 )) % 4 + 2;
    // nPlanets = 5;

    return nPlanets;
  }


  function getPlanetRadii(bytes32 randomish, uint16 nPlanets) external pure returns (uint16[] memory) {

    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint8 nNonGas;
    
    for (uint i=0; i<nPlanets; i++) {
      plRadii[i] = uint16(bytes2(0x0000) | ( bytes2(randomish[i+13]) >> 8 )) % 24 + 10;
      // plRadii[i] = 33;

      // Keep track of n non-gas planets. Want at least 1 planet that players can land on
      if (plRadii[i] < 20) {
        nNonGas++;
      }
    }

    // If all planets are gas, make the one closest to star a rocky (or possibly) earth-like world
    if (nNonGas == 0) {
      plRadii[0] = uint16(bytes2(0x0000) | ( bytes2(randomish[13]) >> 8 )) % 10 + 10;
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


  function getPlanetCategories(uint16[] memory plRadii, uint16[] memory plOrbDist, uint16 starRadius) external pure returns (uint8[] memory) {

    uint8[] memory plCategory = new uint8[] (plRadii.length);
    uint16[2] memory habitableBounds = [starRadius + 125, starRadius + 250];

    for (uint i=0; i<plRadii.length; i++) {
      // Gas Giant
      if (plRadii[i] > 19) {
        plCategory[i] = 0;
      } else {
        // Earth-like water world (within habitable zone)
        if (plOrbDist[i] >= habitableBounds[0] && plOrbDist[i] <= habitableBounds[1]) {
          plCategory[i] = 2;
        } 
        // Rocky planet (Mars-like)
        else {
          plCategory[i] = 1;
        }
      }
    }

    return plCategory;
  }


  function getPlanetHues(bytes32 randomish, uint256 index, uint8 plCategory) external pure returns (uint16[5] memory plHues) {
    bytes32 randomishB = keccak256(abi.encodePacked( randomish, index, plCategory));

    // Gas giant
    if (plCategory == 0) {
      plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 360;
      plHues[1] = uint16( bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 360;
      plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 360;
      plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 360;
      plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 360;
    }
    // Rocky planet 
    else if (plCategory == 1) {
      // plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 121;
      // plHues[1] = plHues[0] + uint16(bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 11;
      // plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 131;
      // plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 131;
      // plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 131;

      plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 340;
      plHues[1] = plHues[0] + uint16( bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 21;
      plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 360;
      plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 360;
      plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 360;
    }
    // Water world 
    else {
      plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 36 + 170;
      plHues[1] = uint16( bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 51;
      plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 51;
      plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 71 + 70;
      plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 71 + 70;
    }

    return plHues;
  }


  function getPlanetTurbScale(bytes32 randomish, uint256 index, uint8 plCategory) external pure returns (uint16 turbScale) {

    // Gas giant
    if (plCategory == 0) {
      turbScale = uint16(bytes2(0x0000) | ( bytes2(randomish[index+18]) >> 8 )) % 8 + 7;
    }
    // Rocky planet 
    else if (plCategory == 1) {
      turbScale = uint16(bytes2(0x0000) | ( bytes2(randomish[index+18]) >> 8 )) % 21 + 20;
    }
    // Water world 
    else {
      turbScale = uint16(bytes2(0x0000) | ( bytes2(randomish[index+18]) >> 8 )) % 23 + 18;
    }

    return turbScale;
  }

  function getPlanetCategoriesCounts(uint8[] memory plCategory) external pure returns (uint8 nGas, uint8 nRocky, uint8 nHabitable) {
    
    for (uint i=0; i<plCategory.length; i++) {
      if (plCategory[i] == 0) {
        nGas++;
      }
      else if (plCategory[i] == 1) {
        nRocky++;
      }
      else {
        nHabitable++;
      }
    }

    return (nGas, nRocky, nHabitable);

  }

}