pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import "@prb/math/contracts/PRBMathSD59x18.sol";
import 'hardhat/console.sol';

import './HexStrings.sol';
import './ToColor.sol';
// import './Trigonometry.sol';

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

// type Ufixed24x3 is int256;

contract CalculateLayout {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using PRBMathSD59x18 for int256;

  // function calcStarColor(int256 starTemp) public returns (int256) {
  //   int256 red;
  //   int256 green;
  //   int256 blue;
  //   int256 foo = 5e18;
  //   int256 power = -1e18 / 2e18;

  //   console.logInt(starTemp);
  //   starTemp = starTemp / 100;

  //   if (starTemp <= 66){
  //     red = 255;
  //   } else {
  //     red = red - 60;
  //     // red = 329698727446e9 * (red.pow(-1e19));
  //   }
  //   red = foo.pow(power);
  //   console.logInt(red);
  // }

  // uint public predictableRandom;
  // uint public predictableRandom2;
  // uint public predictableRandom3;
  
  // function testRandom() public {
  //   predictableRandom = uint(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) )));
  //   predictableRandom2 = predictableRandom % 7;
  //   predictableRandom3 = predictableRandom % 8;
  // }

  // uint256 public output;
  // function testOffset(uint256 input) public {
  //   output = input / 10; 
  // }

  function max(uint256[] memory numbers) public returns (uint256) {
    require(numbers.length > 0); // throw an exception if the condition is not met
    uint256 maxNumber; // default 0, the lowest value of `uint256`

    for (uint256 i = 0; i < numbers.length; i++) {
        if (numbers[i] > maxNumber) {
            maxNumber = numbers[i];
        }
    }

    return maxNumber;
  }

}
