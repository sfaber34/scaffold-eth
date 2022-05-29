// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';
import "hardhat/console.sol";

interface ISystemData {
  function createSystem(uint256) external view returns (Structs.System memory, Structs.Planet[] memory);
}

contract Test {

  Structs.System[] public systems;
  Structs.Planet[] public planets;

  bytes32 public predictableRandomA;
  bytes32 public predictableRandomB;
  uint256 public prToUint;
  bytes1 public b1;
  bytes2 public b2;
  uint8 public u8;
  uint16 public u16;

    function prTest() public {
      predictableRandomA = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp ));
      prToUint = uint256(predictableRandomA);
      predictableRandomB = bytes32(prToUint);

      b1 = bytes1(predictableRandomA[0]);
      b2 = bytes2(predictableRandomA[0]);
      u8 = uint8(bytes1(predictableRandomA[0]));
      u16 = uint16(bytes2(predictableRandomA[0]));
    }  

}