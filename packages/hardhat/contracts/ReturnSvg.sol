// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Trigonometry.sol';
import './Structs.sol';
import 'hardhat/console.sol';

interface ISystemData {
  function getPlanet(uint256) external view returns (Structs.Planet[] memory planets);
  function getSystem(uint256) external view returns (Structs.System memory system);
}

library ReturnSvg {

  using Trigonometry for uint256;
  
  function calcPlanetXY(uint256 rDist, uint256 rads) internal view returns (int256, int256) {
    int256 rDist = int256(rDist);
    int256 cx = (rDist * rads.cos() + 500e18) / 1e18;
    int256 cy = (rDist * rads.sin() + 500e18) / 1e18;

    return (cx, cy);
  }

  function calcPlanetGradAngle(uint256 rads) internal view returns (int256, int256, int256, int256) {
    int256 gradX1 = (50e18 + rads.cos() * 50) / 1e18; 
    int256 gradY1 = (50e18 + rads.sin() * 50) / 1e18;
    int256 gradX2 = (50e18 + (rads + Trigonometry.PI).cos() * 50) / 1e18;  
    int256 gradY2 = (50e18 + (rads + Trigonometry.PI).sin() * 50) / 1e18; 

    return (gradX1, gradY1, gradX2, gradY2);
  }   

  function returnSvg(uint256 id, address systemDataAddress) external view returns (string memory) {
    Structs.Planet[] memory planets = ISystemData(systemDataAddress).getPlanet(id);
    Structs.System memory system = ISystemData(systemDataAddress).getSystem(id);

    uint64[8] memory angles = [0e18, 89759e13, 17951e14, 26927e14, 35903e14, 44879e14, 53855e14, 62831e14];
    // string[7] memory planetColors = ['2d8546', '2e6982', '82592e', '432e82', '2e7582', '824b2e', '5e822e'];

    bytes32 randomish = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));

    // uint64[8] memory anglesRandom;
    // for (uint i=0; i<anglesRandom.length; i++) {
    //   uint randAnglesI = uint(keccak256(abi.encodePacked( randomish, i ))) % 7;
    //   anglesRandom[i] = angles[randAnglesI];
    // }
    
    // Star radial gradient
    string memory render = string(abi.encodePacked(
      '<defs>',
      '<radialGradient id="star" r="65%" spreadMethod="pad">',
        '<stop offset="0%" stop-color="#ffffff" stop-opacity="1" />',
        '<stop offset="60%" stop-color="#',
          system.color,
        '" stop-opacity="1" />',
        '<stop offset="80%" stop-color="#000000" stop-opacity="0" />',
      '</radialGradient>'
    ));

    // Planet linear gradients
    for (uint i=0; i<planets.length; i++) {
      (int256 gradX1, int256 gradY1, int256 gradX2, int256 gradY2) = calcPlanetGradAngle(uint256(angles[i]));
      
      render = string(abi.encodePacked(
        render,
        '<linearGradient id="',
        uint2str(i),
        '" x1="',
        uint2str(uint256(gradX1)),
        '%" y1="',
        uint2str(uint256(gradY1)),
        '%" x2="',
        uint2str(uint256(gradX2)),
        '%" y2="',
        uint2str(uint256(gradY2)),
        '%" spreadMethod="pad">',
          '<stop offset="',
          // uint2str(planets[i].orbDist / 10), // Stack too deep error. Want something like this to make further planets darker
          '25',
          '%" stop-color="#000000" stop-opacity="1" />',
          '<stop offset="100%" stop-color="#',
          // planetColors[i],
          planets[i].color,
          '" stop-opacity="1" />',
        '</linearGradient>'
      ));
    }

    render = string(abi.encodePacked(
      render,
      '</defs>'
    ));

    // Background Star Field
    for (uint i=0; i<60; i++) {
      uint xRand = uint(keccak256(abi.encodePacked( randomish, i ))) % 1000;
      uint yRand = uint(keccak256(abi.encodePacked( randomish, xRand ))) % 1000;
      uint opacityRand = uint(keccak256(abi.encodePacked( randomish, yRand ))) % 25 + 25;

      // bytes32 predictableRandom = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      // color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      // chubbiness[id] = 35+((55*uint256(uint8(predictableRandom[3])))/255);
      // small chubiness loogies have small mouth
      // mouthLength[id] = 180+((uint256(chubbiness[id]/4)*uint256(uint8(predictableRandom[4])))/255);

      render = string(abi.encodePacked(
        render,
        '<circle cx="',
        uint2str(xRand),
        '" cy="',
        uint2str(yRand),
        '" r="1" style="fill: #ffffff; fill-opacity: 0.',
        uint2str(opacityRand),
        ';"></circle>'
      ));
    }

    // System Star
    render = string(abi.encodePacked(
      render,
      '<circle cx="500" cy="500" r="',
      uint2str(system.radius),
      '" style="fill:url(#star);" />'
    ));

    // Planets
    for (uint i=0; i<planets.length; i++) {
      (int256 cx, int256 cy) = calcPlanetXY(planets[i].orbDist, uint256(angles[i]));
      
      uint16 orbTime = planets[i].orbDist / 14;

      render = string(abi.encodePacked(
        render,
        '<circle cx="',
        uint2str(uint256(cx)),
        '" cy="',
        uint2str(uint256(cy)),
        '" r="',
        uint2str(planets[i].radius),
        '" style="fill:url(#',
        uint2str(i),
        ');">',
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" begin="0s" dur="',
          uint2str(orbTime),
          's" repeatCount="indefinite" additive="sum" />',
        '</circle>'
      ));
    }

    // Text
    render = string(abi.encodePacked(
      render,
      '<text x="20" y="980" style="font-family: Courier New; fill: #ffffff; font-size: 32px;" text-anchor="start">',
      system.name,
      '</text>',
      '<text x="980" y="980" style="font-family: Courier New; fill: #ffffff; font-size: 32px;" text-anchor="end">',
      uint2str(system.distToSol),
      ' ly to Sol</text>'
    ));

    return render;
  }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}