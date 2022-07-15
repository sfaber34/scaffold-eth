// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './Uint2Str.sol';
import './ToColor.sol';

contract PopulateSystemLayoutStructs {

  using ToColor for bytes3;
  using Uint2Str for uint16;


  function populateSystemLayoutStructs(bytes32 randomish) external view returns (Structs.System memory system, Structs.Planet[] memory) {
    system.name = generateSystemName(randomish);
    system.coordinates = getSystemCoordinates(randomish);

    system.entropy = getExtraEntropy(randomish, 0);

    system.radius = getStarRadius(randomish);
    system.hue = getStarHue(randomish, system.radius);
    system.category = getStarCategory(system.radius);

    uint16 nPlanets = getNPlanets(randomish);
    uint16[] memory plRadii = getPlanetRadii(randomish, nPlanets);
    uint16[] memory plOrbDist = getPlanetOrbitDistance(system.radius, plRadii);
    uint8[] memory plCategory = getPlanetCategories(plRadii, plOrbDist, system.radius);

    (uint8 nGas, uint8 nRocky, uint8 nHabitable) = getPlanetCategoriesCounts(plCategory);
    system.nGas = nGas;
    system.nRocky = nRocky;
    system.nHabitable = nHabitable;
    
    Structs.Planet[] memory planets = new Structs.Planet[] (plRadii.length);
    // using unchecked to save gas
    for (uint i=0; i<plRadii.length;) {
      planets[i].entropy = getExtraEntropy(randomish, i);

      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].category = plCategory[i];

      uint16[5] memory plHues = getPlanetHues(randomish, i, plCategory[i]);
      uint16 turbScale = getPlanetTurbScale(randomish, i, plCategory[i]);

      planets[i].turbScale = turbScale;
      planets[i].hueA = plHues[0];
      planets[i].hueB = plHues[1];
      planets[i].hueC = plHues[2];
      planets[i].hueD = plHues[3];
      planets[i].hueE = plHues[4];
      unchecked {
        ++ i;
      }
    }

    return (system, planets);
  }


  function generateSystemName(bytes32 randomish) public pure returns (string memory) {
    string[24] memory greekAlphabet = [
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
      'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
      'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
      'Phi', 'Chi', 'Psi', 'Omega'
    ]; 
    
    string[49] memory parentName = [
      'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
      'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
      'Mantis', 'Archer', 'Ares', 'Icarus', 'Baal', 'Eros',
      'Tycho',  'Vesta',  'Zephyr', 'Aether', 'Gaia', 'Hypnos',
      'Invictus', 'Minerva', 'Aurora', 'Decima', 'Febris', 
      'Fides', 'Honos', 'Hora', 'Inuus', 'Nixi', 'Pax',
      'Spes', 'Aamon', 'Baku', 'Boruta', 'Chemosh', 'Dajjal',
      'Grigori', 'Gorgon', 'Mazoku', 'Qin', 'Raum', 'Chax',
      'Tengu', 'Ur', 'Vepar', 'Lazarus'
    ];

    string[12] memory tert = [
      'Sector', 'Region', 'Quadrant', 'Reach', 'Zone', 'Tract',
      'Expanse', 'Extent', 'Province', 'Territory', 'Span',
      'Locus'
    ];

    string memory name = string(abi.encodePacked(
      greekAlphabet[uint8(bytes1(randomish[0])) % greekAlphabet.length],
      ' ',
      parentName[uint8(bytes1(randomish[1])) % parentName.length],
      ' ',
      tert[uint8(bytes1(randomish[2])) % tert.length],
      '-',
      ( bytes2(randomish[3]) | ( bytes2(randomish[4]) >> 8 ) | ( bytes3(randomish[5]) >> 16 ) ).toColor()
    ));

    return name; 
  }


  function getSystemCoordinates(bytes32 randomish) public pure returns (uint16[2] memory coordinates) {
    coordinates[0] = uint16(bytes2(randomish[6]) | ( bytes2(randomish[7]) >> 8 ));
    coordinates[1] = uint16(bytes2(randomish[8]) | ( bytes2(randomish[9]) >> 8 ));

    return coordinates;
  }


  function getExtraEntropy(bytes32 randomish, uint index) public view returns (bytes32) {
    bytes32 entropy = keccak256(abi.encodePacked( randomish, index, msg.sender));

    return entropy;
  }


  function getStarRadius(bytes32 randomish) public pure returns (uint16 starRadius) {
    starRadius = uint16(bytes2(0x0000) | ( bytes2(randomish[10]) >> 8 )) % 71 + 20; 

    return starRadius;
  }


  function getStarHue(bytes32 randomish, uint16 starRadius) public pure returns (uint16 starHue) {
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


  function getStarCategory(uint16 starRadius) public pure returns (string memory starCategory) {
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


  function getNPlanets(bytes32 randomish) public pure returns (uint16 nPlanets) {
    nPlanets = uint16(bytes2(0x0000) | ( bytes2(randomish[12]) >> 8 )) % 4 + 2;

    return nPlanets;
  }


  function getPlanetRadii(bytes32 randomish, uint16 nPlanets) public pure returns (uint16[] memory) {
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint8 nNonGas;
    // using unchecked to save gas
    for (uint i=0; i<nPlanets;) {
      plRadii[i] = uint16(bytes2(0x0000) | ( bytes2(randomish[i+13]) >> 8 )) % 24 + 10;

      // Keep track of n non-gas planets. Want at least 1 planet that players can land on
      if (plRadii[i] < 20) {
        nNonGas++;
      }
      unchecked {
        ++ i;
      }
    }

    // If all planets are gas, make the one closest to star a rocky (or possibly) earth-like world
    if (nNonGas == 0) {
      plRadii[0] = uint16(bytes2(0x0000) | ( bytes2(randomish[13]) >> 8 )) % 10 + 10;
    }

    return plRadii;
  }


  function getPlanetOrbitDistance(uint16 starRadius, uint16[] memory plRadii) public pure returns (uint16[] memory) {
    uint16[] memory plOrbDist = new uint16[] (plRadii.length);

    uint16 plDiamSum;  

    // Keep running sum of pixels that planets would occupy if stacked from edge of star outward
    // using unchecked to save gas
    for (uint i=0; i<plRadii.length;) {
      plDiamSum += plRadii[i] * 2;
      unchecked {
        ++ i;
      }
    }

    // The number of pixels to add between each planet to spread them out evenly.
    uint16 orbDeadSpace = (500 - starRadius - plDiamSum) / uint16(plRadii.length);
    
    plOrbDist[0] = starRadius + plRadii[0] + orbDeadSpace;

    // using unchecked to save gas
    for (uint i=1; i<plRadii.length;) {
      plOrbDist[i] = plOrbDist[i-1] + plRadii[i-1] + plRadii[i] + orbDeadSpace;
      unchecked {
        ++ i;
      }
    }

    return plOrbDist;
  }


  function getPlanetCategories(uint16[] memory plRadii, uint16[] memory plOrbDist, uint16 starRadius) public pure returns (uint8[] memory) {
    uint8[] memory plCategory = new uint8[] (plRadii.length);
    uint16[2] memory habitableBounds = [starRadius + 125, starRadius + 250];

    // using unchecked to save gas
    for (uint i=0; i<plRadii.length;) {
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
      unchecked {
        ++ i;
      }
    }

    return plCategory;
  }


  function getPlanetHues(bytes32 randomish, uint256 index, uint8 plCategory) public pure returns (uint16[5] memory plHues) {
    bytes32 randomishB = keccak256(abi.encodePacked( randomish, index));

    // Water world (hues restricted to blues, greens, reds)
    if (plCategory == 2) {
      plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 36 + 170;
      plHues[1] = uint16( bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 51;
      plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 51;
      plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 71 + 70;
      plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 71 + 70;
    }
    // Gas Giant or rocky dead world (hues are anything)
    else {
      plHues[0] = uint16( bytes2(randomishB[0]) | ( bytes2(randomishB[1]) >> 8 ) ) % 360;
      plHues[1] = uint16( bytes2(randomishB[2]) | ( bytes2(randomishB[3]) >> 8 ) ) % 360;
      plHues[2] = uint16( bytes2(randomishB[4]) | ( bytes2(randomishB[5]) >> 8 ) ) % 360;
      plHues[3] = uint16( bytes2(randomishB[6]) | ( bytes2(randomishB[7]) >> 8 ) ) % 360;
      plHues[4] = uint16( bytes2(randomishB[8]) | ( bytes2(randomishB[9]) >> 8 ) ) % 360;
    }

    return plHues;
  }


  function getPlanetTurbScale(bytes32 randomish, uint256 index, uint8 plCategory) public pure returns (uint16 turbScale) {
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


  function getPlanetCategoriesCounts(uint8[] memory plCategory) public pure returns (uint8 nGas, uint8 nRocky, uint8 nHabitable) {
    // using unchecked to save gas
    for (uint i=0; i<plCategory.length;) {
      if (plCategory[i] == 0) {
        nGas++;
      }
      else if (plCategory[i] == 1) {
        nRocky++;
      }
      else {
        nHabitable++;
      }
      unchecked {
        ++ i;
      }
    }

    return (nGas, nRocky, nHabitable);
  }

}