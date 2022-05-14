// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Trigonometry.sol';
import './Structs.sol';
import 'hardhat/console.sol';

// Start Here: Get planet radial gradient to use some variation of main planet color.
// Change spin time based on orbit distance 
// Fix background star field randomness
// Fix orbit gap. It's slightly too much for test system

interface ISystemData {
  function getPlanet(uint256) external view returns (Structs.Planet[] memory planets);
  function getSystem(uint256) external view returns (Structs.System memory system);
}

library ReturnSvg {

  using Trigonometry for uint256;
  
  function calcPlanetXY(uint256 rDist, uint256 rads) internal view returns (uint256, uint256) {
    int256 rDist = int256(rDist);
    int256 cx = (rDist * rads.cos() + 500e18) / 1e18;
    int256 cy = (rDist * rads.sin() + 500e18) / 1e18;

    return (uint256(cx), uint256(cy));
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

    // uint64[8] memory angles = [0e18, 89759e13, 17951e14, 26927e14, 35903e14, 44879e14, 53855e14, 62831e14];
    uint64[8] memory angles = [0e18, 44879e14, 89759e13, 26927e14, 62831e14, 35903e14, 17951e14, 53855e14];

    bytes32 randomish = keccak256(abi.encodePacked( address(this) ));
    // bytes32 randomishB = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this) ));
    
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
      render = string(abi.encodePacked(
        render,
        '<radialGradient id="',
        uint2str(i),
        '" r="50%">',
          '<stop offset="15%" stop-color="#ffffff"/>',
          '<stop offset="65%" stop-color="hsl(250, 73%, 40%)"/>',
          '<stop offset="95%" stop-color="hsl(250, 73%, 20%)"/>',
        '</radialGradient>'
      ));
    }

    render = string(abi.encodePacked(
      render,
      '<filter id="smear" x="-50%" y="-50%" width="200%" height="200%">',
        '<feTurbulence baseFrequency=".08" numOctaves="10" result="lol" />',
        '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="20" xChannelSelector="R" yChannelSelector="G" />',
        '<feComposite operator="in" in2="SourceGraphic" />',
      '</filter>',
      '<linearGradient id="shadow" x1="100%" y1="0%" x2="0%" y2="0%" spreadMethod="pad">',
        '<stop offset="30%" stop-color="#000000" stop-opacity="1" />',
        '<stop offset="40%" stop-color="#000000" stop-opacity=".9" />',
        '<stop offset="60%" stop-color="#000000" stop-opacity="0" />',
      '</linearGradient>',
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
      Structs.Planet memory thisPlanet = planets[i];

      // (string memory cx, string memory cy) = calcPlanetXY(thisPlanet.orbDist, uint256(angles[i]));
      (uint256 cx, uint256 cy) = calcPlanetXY(thisPlanet.orbDist, uint256(angles[i]));
      
      uint16 orbTime = thisPlanet.orbDist / 14;
      uint256 rotate = uint256(angles[i]) * 180 / Trigonometry.PI;

      
      render = string(abi.encodePacked(
        render,
        '<g>',
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" begin="0s" dur="',
          uint2str(orbTime),
          's" repeatCount="indefinite" additive="sum" />',
          '<circle cx="',
          uint2str(cx),
          '" cy="',
          uint2str(cy),
          '" r="',
          uint2str(thisPlanet.radius),
          '" fill="#',
          thisPlanet.color,
          '"></circle>',
          '<circle cx="',
          uint2str(cx),
          '" cy="',
          uint2str(cy),
          '" r="',
          uint2str(thisPlanet.radius),
          '" style="fill:url(#',
          '0',
          ');" filter="url(#smear)">'
      ));

      render = string(abi.encodePacked(
        render,
            '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 ',
            uint2str(cx),
            ' ',
            uint2str(cy),
            '" to="360 ',
            uint2str(cx),
            ' ',
            uint2str(cy),
            '" begin="0s" dur="',
            '2',
            's" repeatCount="indefinite" additive="sum" />',
          '</circle>',
          '<circle cx="',
          uint2str(cx),
          '" cy="',
          uint2str(cy),
          '" r="',
          uint2str(thisPlanet.radius + 2),
          '" style="fill:url(#shadow);" transform="rotate(',
          uint2str(rotate),
          ', ',
          uint2str(cx),
          ', ',
          uint2str(cy),
          ')"></circle>',
        '</g>'
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