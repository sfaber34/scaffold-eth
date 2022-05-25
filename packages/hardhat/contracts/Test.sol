// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';

contract Test {

  string[17] public parentName = [
    'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
    'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
    'Mantis', 'Archer', 'Ares', 'Icarus',
    'Tycho',  'Vesta',  'Zephyr'
  ];

  string[24] public greekAlphabet = [
    'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
    'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
    'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
    'Phi', 'Chi', 'Psi', 'Omega'
  ]; 

  bytes32 public predictableRandom;
  string public name;

  function generateName() public {
    predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));

    name = string(abi.encodePacked(
      parentName[uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % parentName.length-1],
      ' ',
      greekAlphabet[uint16(bytes2(predictableRandom[1]) | ( bytes2(predictableRandom[2]) >> 8 )) % greekAlphabet.length-1],
      '-'
    ));
  }

    // bytes16 internal constant ALPHABET = '0123456789abcdef';

    // function toColor2(bytes2 value) public pure returns (string memory) {
    //   bytes memory buffer = new bytes(4);
    //   for (uint256 i = 0; i < 2; i++) {
    //       buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
    //       buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
    //   }
    //   return string(buffer);
    // }
}