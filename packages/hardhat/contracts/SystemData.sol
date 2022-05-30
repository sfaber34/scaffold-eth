// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
import './ToColor.sol';
import './Uint2Str.sol';

// import "hardhat/console.sol";

//Note: Not sure that the method for planet colors is as random as could be (the way i'm doing byte positions)

contract SystemData {

  using ToColor for bytes3;
  using Uint2Str for uint16;
  // using SystemNames for string;

  function createSystem(uint256 id) external pure returns (Structs.System memory, Structs.Planet[] memory) {

    bytes32 predictableRandom = bytes32(id);
    // Pick number of planets and system sector
    uint16 nPlanets = uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % 5 + 2;

    Structs.System memory system;
    Structs.Planet[] memory planets = new Structs.Planet[] (nPlanets);

    system.name = generateSystemName(id);
    system.radius = uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[7]) >> 8 )) % 70 + 20;
    system.colorH = uint16(bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 )) % 40 + 5;
    system.sequence = 'main sequence';

    uint16 plDiamSum;
    uint16 orbDeadSpace; 
    uint16[] memory plRadii = new uint16[] (nPlanets);
    uint16[] memory plOrbDist = new uint16[] (nPlanets);
    for (uint i=0; i<nPlanets; i++) {
      // plRadii[] pushed to Planets struct below but need to do checks on layout first
      plRadii[i] = uint16(bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 )) % 23 + 5;
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
      planets[i].colorA = ( bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 ) | ( bytes3(predictableRandom[i+2]) >> 16 ) ).toColor();
      planets[i].colorB = ( bytes2(predictableRandom[i+9]) | ( bytes2(predictableRandom[i+10]) >> 8 ) | ( bytes3(predictableRandom[i+11]) >> 16 ) ).toColor();
      planets[i].colorC = ( bytes2(predictableRandom[i+19]) | ( bytes2(predictableRandom[i+20]) >> 8 ) | ( bytes3(predictableRandom[i+21]) >> 16 ) ).toColor();
      planets[i].colorD = ( bytes2(predictableRandom[i+26]) | ( bytes2(predictableRandom[20-i]) >> 8 ) | ( bytes3(predictableRandom[i+9]) >> 16 ) ).toColor();

      // Make the star a blue dwarf (hue:200-240) if any planet radii is within 10 px of star radius
      for (uint i=0; i<nPlanets; i++){
        if (plRadii[i] > system.radius - 10){
          system.colorH = uint16(bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 )) % 40 + 200;
          system.sequence = 'blue dwarf';
        }
      }
    }

    return (system, planets);
  }

  function generateSystemName(uint256 id) internal pure returns (string memory) {
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

    string[24] memory greekAlphabet = [
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
      'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
      'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
      'Phi', 'Chi', 'Psi', 'Omega'
    ]; 

    string[12] memory tert = [
      'Sector', 'Region', 'Quadrant', 'Reach', 'Zone', 'Tract',
      'Expanse', 'Extent', 'Province', 'Territory', 'Span',
      'Locus'
    ];

    bytes32 predictableRandom = bytes32(id);

    // bytes3 nameBytes = bytes3(bytes.concat( bytes2(predictableRandom[13]), bytes2(predictableRandom[14]), bytes2(predictableRandom[15])  )).toColor();

    string memory name = string(abi.encodePacked(
      greekAlphabet[uint8(bytes1(predictableRandom[0])) % greekAlphabet.length],
      ' ',
      parentName[uint8(bytes1(predictableRandom[1])) % parentName.length],
      ' ',
      tert[uint8(bytes1(predictableRandom[2])) % tert.length],
      '-',
      ( bytes2(predictableRandom[29]) | ( bytes2(predictableRandom[30]) >> 8 ) | ( bytes3(predictableRandom[31]) >> 16 ) ).toColor()
    ));

    return name; 
  }

    // string memory name;
    // uint i=0;
    // uint8 nMatch;

    // bytes32 predictableRandom = bytes32(id);
    // // Attempt to find a unique name combo 20 times
    // do {
    //   name = string(abi.encodePacked(
    //     // Error: VM Exception while processing transaction: reverted with panic code 0x11 (Arithmetic operation underflowed or overflowed outside of an unchecked block)
    //     greekAlphabet[uint16(bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 )) % greekAlphabet.length],
    //     ' ',
    //     parentName[uint16(bytes2(predictableRandom[i+2]) | ( bytes2(predictableRandom[i+3]) >> 8 )) % parentName.length],
    //     ' ',
    //     tert[uint16(bytes2(predictableRandom[i+4]) | ( bytes2(predictableRandom[i+5]) >> 8 )) % tert.length] 
    //   ));

    //   // Loop previous names to see if there's a match with new name
    //   for (uint k=0; k<systems.length; k++) {
    //     if (keccak256(abi.encode(systems[k].name)) == keccak256(abi.encode(name))) {
    //       nMatch++; // Incremented to compare later with i (name iteration)
    //       break;
    //     }
    //   }
    //   // New name is unique. Force loop to exit
    //   if (i >= nMatch) {
    //     i=30;
    //   }

    //   i++;
    // } while (i < 20);
    
    // require(nMatch < i , "Could not find unique name combination in 20 tries");

    // return name;
  
}

