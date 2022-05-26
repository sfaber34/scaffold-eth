// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';
import "hardhat/console.sol";

interface ISystemData {
  function getPlanet(uint256) external view returns (Structs.Planet[] memory planets);
  function getSystem(uint256) external view returns (Structs.System memory system);
  function createSystem() external;
}

contract Test {

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  // string[17] public parentName = [
  //   'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
  //   'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
  //   'Mantis', 'Archer', 'Ares', 'Icarus',
  //   'Tycho',  'Vesta',  'Zephyr'
  // ];

  // string[24] public greekAlphabet = [
  //   'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
  //   'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
  //   'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
  //   'Phi', 'Chi', 'Psi', 'Omega'
  // ]; 

  // bytes32 public predictableRandom;
  // string public name;

  // function generateName() public {
  //   predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));

  //   name = string(abi.encodePacked(
  //     parentName[uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % parentName.length-1],
  //     ' ',
  //     greekAlphabet[uint16(bytes2(predictableRandom[1]) | ( bytes2(predictableRandom[2]) >> 8 )) % greekAlphabet.length-1],
  //     '-'
  //   ));
  // }

    // bytes16 internal constant ALPHABET = '0123456789abcdef';

    // function toColor2(bytes2 value) public pure returns (string memory) {
    //   bytes memory buffer = new bytes(4);
    //   for (uint256 i = 0; i < 2; i++) {
    //       buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
    //       buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
    //   }
    //   return string(buffer);
    // }

    function generateSystemName() public view returns (string memory) {
    string[48] memory parentName = [
      'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
      'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
      'Mantis', 'Archer', 'Ares', 'Icarus', 'Baal', 'Eros',
      'Tycho',  'Vesta',  'Zephyr', 'Aether', 'Gaia', 'Hypnos',
      'Invictus', 'Minerva', 'Aurora', 'Decima', 'Febris', 
      'Fides', 'Honos', 'Hora', 'Inuus', 'Nixi', 'Pax',
      'Spes', 'Aamon', 'Baku', 'Boruta', 'Chemosh', 'Dajjal',
      'Grigori', 'Gorgon', 'Mazoku', 'Qin', 'Raum', 'Chax',
      'Tengu', 'Ur', 'Vepar'
    ];

    string[24] memory greekAlphabet = [
      'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
      'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
      'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
      'Phi', 'Chi', 'Psi', 'Omega'
    ]; 

    string memory name;
    uint i=0;

    while (i<24) {
      console.log(i);
      bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp ));

      name = string(abi.encodePacked(
        // Error: VM Exception while processing transaction: reverted with panic code 0x11 (Arithmetic operation underflowed or overflowed outside of an unchecked block)
        greekAlphabet[uint16(bytes2(predictableRandom[i]) | ( bytes2(predictableRandom[i+1]) >> 8 )) % greekAlphabet.length],
        ' ',
        parentName[uint16(bytes2(predictableRandom[i+2]) | ( bytes2(predictableRandom[i+3]) >> 8 )) % parentName.length] 
      ));
      
      for (uint k=0; k<systems.length; k++) {
        if (keccak256(abi.encode(systems[i].name)) != keccak256(abi.encode(name))) {
          i=30;
        }
      }
    i++;
    }

    return name;
  }
}