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

    function prTest() public {
      predictableRandomA = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp ));
      prToUint = uint256(predictableRandomA);
      predictableRandomB = bytes32(prToUint);
    }  
    
}