// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ToColor.sol';

library SystemName {

  using ToColor for bytes3;

  function generateSystemName(uint256 id) external pure returns (string memory) {
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

    bytes32 seed = bytes32(id);

    string memory name = string(abi.encodePacked(
      greekAlphabet[uint8(bytes1(seed[0])) % greekAlphabet.length],
      ' ',
      parentName[uint8(bytes1(seed[1])) % parentName.length],
      ' ',
      tert[uint8(bytes1(seed[2])) % tert.length],
      '-',
      ( bytes2(seed[29]) | ( bytes2(seed[30]) >> 8 ) | ( bytes3(seed[31]) >> 16 ) ).toColor()
    ));

    return name; 
  }

}