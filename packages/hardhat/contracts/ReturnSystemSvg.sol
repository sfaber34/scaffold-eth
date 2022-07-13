// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Trigonometry.sol';
import './Structs.sol';
import './Uint2Str.sol';
import './ToColor.sol';

contract ReturnSystemSvg {

  using Trigonometry for uint256;
  using Uint2Str for uint;
  using Uint2Str for uint8;
  using Uint2Str for uint16;
  using ToColor for bytes3;
  
  function calcPlanetXY(uint256 rDist_, uint256 rads) internal pure returns (uint256, uint256) {
    int256 rDist = int256(rDist_);
    int256 cx = (rDist * rads.cos() + 500e18) / 1e18;
    int256 cy = (rDist * rads.sin() + 500e18) / 1e18;

    return (uint256(cx), uint256(cy));
  }


  function returnSystemSvg(Structs.System memory system, Structs.Planet[] memory planets) external pure returns (string memory) {
    
    // Angles used to place planets around star. 0e18 is to the right of the star a y=500.
    uint64[7] memory angles = [0e18, 35904e14, 53856e14, 89759e13, 17952e14, 44880e14, 26928e14];
    
    // Add the star radial gradient
    string memory render = string(abi.encodePacked(
      '<defs>',
      '<radialGradient id="star" r="65%" spreadMethod="pad">',
        '<stop offset="0%" stop-color="hsl(',
        system.hue.uint2Str(),
        ',65%,95%)" stop-opacity="1" />',
        '<stop offset="60%" stop-color="hsl(',
        system.hue.uint2Str(),
        // ',40%,75%)" stop-opacity="1" />',
        ',50%,65%)" stop-opacity="1" />',
        '<stop offset="80%" stop-color="#000000" stop-opacity="0" />',
      '</radialGradient>'
    ));

    // Add planet radial gradients. These will be scrambled by "smear" filter to give planets texture
    for (uint i=0; i<planets.length; i++) {
      string memory planetGradientFilter = getPlanetGradientFilter(i, planets[i]);
      
      render = string(abi.encodePacked(
        render,
        planetGradientFilter
      ));
    }
    // Add shadow gradient and close <defs>
    render = string(abi.encodePacked(
      render,
      '<linearGradient id="shadow" x1="100%" y1="0%" x2="0%" y2="0%" spreadMethod="pad">',
        '<stop offset="30%" stop-color="#000000" stop-opacity="1" />',
        '<stop offset="40%" stop-color="#000000" stop-opacity=".9" />',
        '<stop offset="60%" stop-color="#000000" stop-opacity="0" />',
      '</linearGradient>',
      '</defs>'
    ));

    // Draw the system star
    render = string(abi.encodePacked(
      render,
      '<circle cx="500" cy="500" r="',
      system.radius.uint2Str(),
      '" style="fill:url(#star);" />'
    ));

    // Draw planets. Each planet has 3 circles; a base with a solid fill, the spinning overlay with radial gradient/smear filter, and
    // a top circle with linear gradient for the shadow.
    // The abi.encodePacked() is split to avoid stack overflows
    for (uint i=0; i<planets.length; i++) {
      // Recast to avoid stack overflows
      Structs.Planet memory thisPlanet = planets[i];

      (uint256 cx, uint256 cy) = calcPlanetXY(thisPlanet.orbDist, uint256(angles[i]));

      // Number of degrees to rotate the planet shadow layer so it's lined up with system star.
      uint256 rotate = uint256(angles[i]) * 180 / Trigonometry.PI;

      // Render is split into 2 to avoid stack overflows 
      render = string(abi.encodePacked(
        render,
        '<g>',
          '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 500 500" to="360 500 500" begin="0s" dur="',
          (thisPlanet.orbDist / 10).uint2Str(), // Rough scaling to make further planets orbit slower
          's" repeatCount="indefinite" additive="sum" />',
          '<circle cx="',
          cx.uint2Str(),
          '" cy="',
          cy.uint2Str(),
          '" r="',
          (thisPlanet.radius).uint2Str(),
          '" fill="hsl(',
          thisPlanet.hueA.uint2Str(),
          ', 90%, 40%)"></circle>',
          '<circle cx="',
          cx.uint2Str(),
          '" cy="',
          cy.uint2Str(),
          '" r="',
          (thisPlanet.radius).uint2Str(),
          '" style="fill:url(#',
          i.uint2Str(),
          ');" filter="url(#smear',
          i.uint2Str(),
          ')">'
      ));

      render = string(abi.encodePacked(
        render,
            '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 ',
            cx.uint2Str(),
            ' ',
            cy.uint2Str(),
            '" to="360 ',
            cx.uint2Str(),
            ' ',
            cy.uint2Str(),
            '" begin="0s" dur="',
            (thisPlanet.radius * 65 + 500).uint2Str(), // Planet rotation time. Spans ~800 to 3000 ms depending on planet radius
            'ms" repeatCount="indefinite" additive="sum" />',
          '</circle>',
          '<circle cx="',
          cx.uint2Str(),
          '" cy="',
          cy.uint2Str(),
          '" r="',
          (thisPlanet.radius + 2).uint2Str(),
          '" style="fill:url(#shadow);" transform="rotate(',
          rotate.uint2Str(),
          ', ',
          cx.uint2Str(),
          ', ',
          cy.uint2Str(),
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

  function getPlanetGradientFilter(uint i, Structs.Planet memory planet) internal pure returns (string memory planetGradient) {
    uint8 turbBaseFreq;
    uint8 blurDeviation;

    // Gas planet
    if (planet.category == 0) {
      turbBaseFreq = 0;
      blurDeviation = 1;

      planetGradient = string(abi.encodePacked(
        '<radialGradient id="',
        i.uint2Str(),
        '" r="40%">',
          // '<stop offset="5%" stop-color="hsl(',
          // planet.hueB.uint2Str(),
          // ', 90%, 50%)"/>',
          '<stop offset="50%" stop-color="hsl(',
          planet.hueB.uint2Str(),
          ', 90%, 30%)"/>',
          '<stop offset="90%" stop-color="hsl(',
          planet.hueC.uint2Str(),
          ', 90%, 60%)"/>',
          '<stop offset="97%" stop-color="hsl(',
          planet.hueD.uint2Str(),
          ', 70%, 75%)"/>',
          '<stop offset="100%" stop-color="hsl(',
          planet.hueE.uint2Str(),
          ', 90%, 30%)"/>',
        '</radialGradient>'
      ));
    }
    // Rocky planet
    else if (planet.category == 1) {
      turbBaseFreq = 4;
      blurDeviation = 0;

      planetGradient = string(abi.encodePacked(
        '<radialGradient id="',
        i.uint2Str(),
        '" r="100%">',
          '<stop offset="5%" stop-color="hsl(',
          planet.hueB.uint2Str(),
          ', 90%, 50%)"/>',
          '<stop offset="35%" stop-color="hsl(',
          planet.hueC.uint2Str(),
          ', 90%, 10%)"/>',
          '<stop offset="55%" stop-color="hsl(',
          planet.hueD.uint2Str(),
          ', 90%, 60%)"/>',
          '<stop offset="95%" stop-color="hsl(',
          planet.hueE.uint2Str(),
          ', 90%, 10%)"/>',
        '</radialGradient>'
      ));
    }
    // Water World
    else if (planet.category == 2) {
      turbBaseFreq = 0;
      blurDeviation = 0;

      planetGradient = string(abi.encodePacked(
        '<radialGradient id="',
          i.uint2Str(),
          '" r="30%">',
          '<stop offset="15%" stop-color="hsl(0, 0%, 100%)"/>',
          '<stop offset="35%" stop-color="hsl(',
          planet.hueB.uint2Str(),
          ', 90%, 10%)"/>',
          '<stop offset="75%" stop-color="hsl(',
          planet.hueC.uint2Str(),
          ', 90%, 50%)"/>',
          '<stop offset="90%" stop-color="hsl(',
          planet.hueD.uint2Str(),
          ', 90%, 40%)"/>',
          '<stop offset="95%" stop-color="hsl(',
          planet.hueE.uint2Str(),
          ', 90%, 20%)"/>',
        '</radialGradient>'
      ));
    }

    string memory planetGradientFilter = string(abi.encodePacked(
      planetGradient,
      '<filter id="smear',
      i.uint2Str(),
      '">',
        '<feTurbulence baseFrequency="',
        turbBaseFreq.uint2Str(),
        '.08" numOctaves="10" result="turbulence" />',
        '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',
        planet.turbScale.uint2Str(),
        '" xChannelSelector="R" yChannelSelector="G" result="displacement"/>',
        '<feGaussianBlur in="displacement" stdDeviation="',
        blurDeviation.uint2Str(),
        '" />',
        '<feComposite operator="in" in2="SourceGraphic" />',
      '</filter>'
    ));

    return planetGradientFilter;
  }

}