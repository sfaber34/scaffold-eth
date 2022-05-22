// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';
// import './ToColor.sol';

contract Test {

  // using ToColor for bytes3;

  bytes32 public predictableRandom;
  bytes2 public colorBytesTwo;
  bytes3 public colorBytesThree;
  // bytes3 public colorBytesC;
  bytes3 public colorBytesConcat;
  string public colorBytesConcatString;
  // bytes4 public bytesFour;

  function test() public {
    predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));

    colorBytesTwo = bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 );
    colorBytesThree = bytes2(predictableRandom[29]) | ( bytes2(predictableRandom[30]) >> 8 ) | ( bytes3(predictableRandom[31]) >> 16 );

    colorBytesConcat = bytes2('ff') | bytes2(predictableRandom[30]) | ( bytes2(predictableRandom[31]) >> 8 );

    colorBytesConcatString = string(abi.encodePacked(
      string('ff'),
      string(toColor2(colorBytesTwo))
    ));
  }

    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toColor(bytes3 value) public pure returns (string memory) {
      bytes memory buffer = new bytes(6);
      for (uint256 i = 0; i < 3; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }

    function toColor2(bytes2 value) public pure returns (string memory) {
      bytes memory buffer = new bytes(4);
      for (uint256 i = 0; i < 2; i++) {
          buffer[i*2+1] = ALPHABET[uint8(value[i]) & 0xf];
          buffer[i*2] = ALPHABET[uint8(value[i]>>4) & 0xf];
      }
      return string(buffer);
    }
}