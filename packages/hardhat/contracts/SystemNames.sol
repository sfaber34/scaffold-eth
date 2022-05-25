// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SystemNames {

  // string[17] constant parentName = [
  //   'Surya', 'Chimera', 'Vulcan', 'Odin', 'Osiris', 
  //   'Grendel', 'Nephilim', 'Leviathan', 'Cepheus', 'Titus', 
  //   'Mantis', 'Archer', 'Ares', 'Icarus',
  //   'Tycho',  'Vesta',  'Zephyr'
  // ];

  // string[24] internal greekAlphabet = [
  //   'Alpha', 'Beta', 'Gamma', 'Delta', 'Epsilon', 'Zeta', 
  //   'Eta', 'Theta', 'Iota', 'Kappa', 'Lambda', 'Mu', 'Nu', 
  //   'Xi', 'Omikron', 'Pi', 'Rho', 'Sigma', 'Tau', 'Upsilon', 
  //   'Phi', 'Chi', 'Psi', 'Omega'
  // ];

  // function returnRandomName() external view returns (string memory) {
  //   bytes32 predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp ));

  //   string memory name = string(abi.encodePacked(parentName[uint16(bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 )) % parentName.length-1]));

  //   return name;
  // } 

}