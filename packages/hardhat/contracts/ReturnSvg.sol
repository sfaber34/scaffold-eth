// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Trigonometry.sol';
import './Structs.sol';

interface ISystemData {
  function getPlanet(uint256) external view returns (Structs.Planet[] memory planets);
  function getSystem(uint256) external view returns (Structs.System memory system);
  function createSystem() external view;
}

library ReturnSvg {

  using Trigonometry for uint256;
  
  function calcPlanetXY(uint256 rDist_, uint256 rads) internal pure returns (uint256, uint256) {
    int256 rDist = int256(rDist_);
    int256 cx = (rDist * rads.cos() + 500e18) / 1e18;
    int256 cy = (rDist * rads.sin() + 500e18) / 1e18;

    return (uint256(cx), uint256(cy));
  }

  function returnSvg(uint256 id, address systemDataAddress) external view returns (string memory) {
    Structs.Planet[] memory planets = ISystemData(systemDataAddress).getPlanet(id);
    Structs.System memory system = ISystemData(systemDataAddress).getSystem(id);
    
    // Angles used to place planets around star. 0e18 is to the right of the star a y=500.
    uint64[10] memory angles = [0e18, 44879e14, 89759e13, 26927e14, 62831e14, 35903e14, 17951e14, 53855e14, 26927e14, 44879e14];
    
    // Add the star radial gradient
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

    // Add planet radial gradients. These will be scrambled by "smear" filter to give planets texture
    for (uint i=0; i<planets.length; i++) {
      render = string(abi.encodePacked(
        render,
        '<radialGradient id="',
        uint2str(i),
        '" r="50%">',
          '<stop offset="15%" stop-color="#ffffff"/>',
          '<stop offset="65%" stop-color="#',
          planets[i].colorC,
          '"/>',
          '<stop offset="95%" stop-color="#',
          planets[i].colorB,
          '"/>',
        '</radialGradient>'
      ));
    }
    // Add filters for scrambling planet radial gradients
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

    // Add background star field. Looks better with more stars but 50 extra svg <circles> is already hard on render/display in app
    // bytes32 predictableRandom;
    // uint8 k;
    // for (uint i=0; i<50; i++) {      
    //   if (i % 28 == 0){ 
    //     k=0;
    //     predictableRandom = keccak256(abi.encodePacked( msg.sender, i ));
    //   }

    //   // Get x/y coordinates between 0 - 1000 pixels and an opacity between .15 and .45
    //   uint16 xRand = uint16(bytes2(predictableRandom[k]) | ( bytes2(predictableRandom[k+1]) >> 8 )) % 1000;
    //   uint16 yRand = uint16(bytes2(predictableRandom[k+2]) | ( bytes2(predictableRandom[k+3]) >> 8 )) % 1000;
    //   uint16 opacityRand = uint16(bytes2(predictableRandom[k]) | ( bytes2(predictableRandom[k+2]) >> 8 )) % 30 + 15;
    //   k++;

    //   render = string(abi.encodePacked(
    //     render,
    //     '<circle cx="',
    //     uint2str(xRand),
    //     '" cy="',
    //     uint2str(yRand),
    //     '" r="2" style="fill: #ffffff; fill-opacity: 0.',
    //     uint2str(opacityRand),
    //     ';"></circle>'
    //   ));
    // }

    // Draw the system star
    render = string(abi.encodePacked(
      render,
      '<circle cx="500" cy="500" r="',
      uint2str(system.radius),
      '" style="fill:url(#star);" />'
    ));

    // Draw planets. Each planet has 3 circles; a base with a solid fill, the spinning overlay with radial gradient/smear filter, and
    // a top circle with linear gradient for the shadow.
    // The abi.encodePacked() is split to avoid stack overflows
    for (uint i=0; i<planets.length; i++) {
      // Recast to avoid stack overflows. Not pretty
      Structs.Planet memory thisPlanet = planets[i];

      (uint256 cx, uint256 cy) = calcPlanetXY(thisPlanet.orbDist, uint256(angles[i]));

      // Number of degrees to rotate the planet shadow layer so it's lined up with system star.
      uint256 rotate = uint256(angles[i]) * 180 / Trigonometry.PI;

      // Render is split into 2 to avoid stack overflows 
      render = string(abi.encodePacked(
        render,
        '<g>',
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" begin="0s" dur="',
          uint2str(thisPlanet.orbDist / 14), // Rough scaling to make further planets orbit slower
          's" repeatCount="indefinite" additive="sum" />',
          '<circle cx="',
          uint2str(cx),
          '" cy="',
          uint2str(cy),
          '" r="',
          uint2str(thisPlanet.radius),
          '" fill="#',
          thisPlanet.colorA,
          '"></circle>',
          '<circle cx="',
          uint2str(cx),
          '" cy="',
          uint2str(cy),
          '" r="',
          uint2str(thisPlanet.radius),
          '" style="fill:url(#',
          uint2str(i),
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
            '2', // Time to complete planet rotation. Should really scale based on planet radius or something
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

    // Add text about system attributes to bottom of svg
    render = string(abi.encodePacked(
      render,
      '<text x="20" y="980" style="font-family: Courier New; fill: #ffffff; font-size: 32px;" text-anchor="start">',
      system.name,
      '</text>'
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