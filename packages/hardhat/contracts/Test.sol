// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';
import "hardhat/console.sol";

contract Test {
  bytes32 public seed = 0x6c6309347ce858a4a9cd95110ae4be03e0018a688c8235b691e0b3391e72b9d6;
  bytes2 public test = bytes2(seed[0]) | ( bytes2(seed[1]) >> 8 );
}