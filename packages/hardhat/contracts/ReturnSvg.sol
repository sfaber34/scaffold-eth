// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Trigonometry.sol';
import './Structs.sol';
import './Uint2Str.sol';

interface ISystemData {
  function getPlanet(uint256) external view returns (Structs.Planet[] memory planets);
  function getSystem(uint256) external view returns (Structs.System memory system);
  function createSystem() external;
}
// Fix this:
// Contract call:       ReturnSvg#<unrecognized-selector>
//   From:                0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266
//   To:                  0xdc64a140aa3e981100a9beca4e685f962f0cf6c9

//   Error: Transaction reverted: library was called directly
//       at ReturnSvg.<unknown> (contracts/ReturnSvg.sol:28)
//       at runMicrotasks (<anonymous>)
//       at processTicksAndRejections (internal/process/task_queues.js:95:5)
//       at HardhatNode.runCall (/Users/spencerfaber/dev/scaffold-eth/forks/exos-random/packages/hardhat/node_modules/hardhat/src/internal/hardhat-network/provider/node.ts:510:20)
//       at EthModule._callAction (/Users/spencerfaber/dev/scaffold-eth/forks/exos-random/packages/hardhat/node_modules/hardhat/src/internal/hardhat-network/provider/modules/eth.ts:353:9)
//       at HardhatNetworkProvider._sendWithLogging (/Users/spencerfaber/dev/scaffold-eth/forks/exos-random/packages/hardhat/node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:127:22)
//       at HardhatNetworkProvider.request (/Users/spencerfaber/dev/scaffold-eth/forks/exos-random/packages/hardhat/node_modules/hardhat/src/internal/hardhat-network/provider/provider.ts:104:18)
//       at JsonRpcHandler._handleRequest (/Users/spencerfaber/dev/scaffold-eth/forks/exos-random/packages/hardhat/node_modules/hardhat/src/internal/hardhat-network/jsonrpc/handler.ts:188:20)

library ReturnSvg {

  using Trigonometry for uint256;
  using Uint2Str for uint;
  using Uint2Str for uint16;
  
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
    // uint64[7] memory angles = [0e18, 89759e13, 17952e14, 26928e14, 35904e14, 44880e14, 53856e14];
    uint64[7] memory angles = [0e18, 35904e14, 53856e14, 89759e13, 17952e14, 44880e14, 26928e14];
    // uint64[8] memory angles = [0e18, 78539e13, 15708e14, 23562e14, 31416e14, 39270e14, 47124e14, 54978e14];
    
    // Add the star radial gradient
    string memory render = string(abi.encodePacked(
      '<defs>',
      '<radialGradient id="star" r="65%" spreadMethod="pad">',
        '<stop offset="0%" stop-color="hsl(',
        system.colorH.uint2Str(),
        ',65%,95%)" stop-opacity="1" />',
        '<stop offset="60%" stop-color="hsl(',
        system.colorH.uint2Str(),
        ',40%,75%)" stop-opacity="1" />',
        '<stop offset="80%" stop-color="#000000" stop-opacity="0" />',
      '</radialGradient>'
    ));

    // Add planet radial gradients. These will be scrambled by "smear" filter to give planets texture
    for (uint i=0; i<planets.length; i++) {
      render = string(abi.encodePacked(
        render,
        '<radialGradient id="',
        i.uint2Str(),
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
        '<feTurbulence baseFrequency=".08" numOctaves="10" result="turbulence" />',
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
    //     predictableRandom = keccak256(abi.encodePacked( blockhash(block.number-1), block.timestamp, msg.sender, i ));
    //   }

    //   // Get x/y coordinates between 0 - 1000 pixels and an opacity between .15 and .45
    //   uint16 xRand = uint16(bytes2(predictableRandom[k]) | ( bytes2(predictableRandom[k+1]) >> 8 )) % 1000;
    //   uint16 yRand = uint16(bytes2(predictableRandom[k+2]) | ( bytes2(predictableRandom[k+3]) >> 8 )) % 1000;
    //   uint16 opacityRand = uint16(bytes2(predictableRandom[k]) | ( bytes2(predictableRandom[k+2]) >> 8 )) % 30 + 15;
    //   k++;

    //   render = string(abi.encodePacked(
    //     render,
    //     '<circle cx="',
    //     xRand.uint2Str(),
    //     '" cy="',
    //     yRand.uint2Str(),
    //     '" r="2" style="fill: #ffffff; fill-opacity: 0.',
    //     opacityRand.uint2Str(),
    //     ';"></circle>'
    //   ));
    // }


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
          (thisPlanet.orbDist / 10).uint2Str(), // Rough scaling to make further planets orbit slower
          's" repeatCount="indefinite" additive="sum" />',
          '<circle cx="',
          cx.uint2Str(),
          '" cy="',
          cy.uint2Str(),
          '" r="',
          (thisPlanet.radius).uint2Str(),
          '" fill="#',
          thisPlanet.colorA,
          '"></circle>',
          '<circle cx="',
          cx.uint2Str(),
          '" cy="',
          cy.uint2Str(),
          '" r="',
          (thisPlanet.radius).uint2Str(),
          '" style="fill:url(#',
          i.uint2Str(),
          ');" filter="url(#smear)">'
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
            (thisPlanet.radius * 65 + 500).uint2Str(), // Planet rotation time. Spans 825 to 3100 ms depending on planet radius
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

}