// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import './Structs.sol';
// import './Uint2Str.sol';
// import './ToColor.sol';

contract ReturnPlanetResources {

  // using ToColor for bytes3;
  // using Uint2Str for uint16;


  function returnPlanetResources(bytes32 randomish, uint256 index, uint8 plCategory) external pure returns (uint8[4] memory resources) {
    bytes32 randomishB = keccak256(abi.encodePacked( randomish, index));

    // resources[0] = uint16(bytes2(0x0000) | ( bytes2(randomishB[10]) >> 8 ));
    resources[0] = uint8( bytes1(randomishB[10]) );
    resources[1] = uint8( bytes1(randomishB[11]) );
    resources[2] = uint8( bytes1(randomishB[12]) );
    resources[3] = uint8( bytes1(randomishB[13]) );

    return resources;
  }

}