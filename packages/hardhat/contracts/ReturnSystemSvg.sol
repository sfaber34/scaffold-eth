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

    // Add background star field. Looks better with more stars but 50 extra svg <circles> is already hard on render/display in app
    // bytes32 randomish;
    // uint8 k;
    // for (uint i=0; i<50; i++) {      
    //   if (i % 28 == 0){ 
    //     k=0;
    //     randomish = keccak256(abi.encodePacked( blockhash(block.number-1), block.timestamp, msg.sender, i ));
    //   }

    //   // Get x/y coordinates between 0 - 1000 pixels and an opacity between .15 and .45
    //   uint16 xRand = uint16(bytes2(randomish[k]) | ( bytes2(randomish[k+1]) >> 8 )) % 1000;
    //   uint16 yRand = uint16(bytes2(randomish[k+2]) | ( bytes2(randomish[k+3]) >> 8 )) % 1000;
    //   uint16 opacityRand = uint16(bytes2(randomish[k]) | ( bytes2(randomish[k+2]) >> 8 )) % 30 + 15;
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

  // string public starField = string(abi.encodePacked('<circle cx="905" cy="407" r="1" style="fill: #ffffff; fill-opacity: 0.26;"></circle>',
  //   '<circle cx="373" cy="349" r="1" style="fill: #ffffff; fill-opacity: 0.42;"></circle>',
  //   '<circle cx="49" cy="850" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="131" cy="84" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="708" cy="789" r="1" style="fill: #ffffff; fill-opacity: 0.15;"></circle>',
  //   '<circle cx="429" cy="828" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="467" cy="164" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="105" cy="115" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="135" cy="95" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="326" cy="645" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="108" cy="143" r="1" style="fill: #ffffff; fill-opacity: 0.16;"></circle>',
  //   '<circle cx="152" cy="583" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="358" cy="285" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="232" cy="969" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="847" cy="577" r="1" style="fill: #ffffff; fill-opacity: 0.47;"></circle>',
  //   '<circle cx="773" cy="684" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="194" cy="508" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="669" cy="976" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="879" cy="816" r="1" style="fill: #ffffff; fill-opacity: 0.3;"></circle>',
  //   '<circle cx="382" cy="320" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="949" cy="874" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="430" cy="559" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="944" cy="25" r="1" style="fill: #ffffff; fill-opacity: 0.36;"></circle>',
  //   '<circle cx="391" cy="132" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="927" cy="943" r="1" style="fill: #ffffff; fill-opacity: 0.22;"></circle>',
  //   '<circle cx="592" cy="557" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="204" cy="529" r="1" style="fill: #ffffff; fill-opacity: 0.44;"></circle>',
  //   '<circle cx="593" cy="462" r="1" style="fill: #ffffff; fill-opacity: 0.26;"></circle>',
  //   '<circle cx="949" cy="626" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="211" cy="722" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="311" cy="345" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="998" cy="427" r="1" style="fill: #ffffff; fill-opacity: 0.41;"></circle>',
  //   '<circle cx="819" cy="757" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="583" cy="383" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="64" cy="82" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="448" cy="352" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="928" cy="285" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="217" cy="397" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="244" cy="634" r="1" style="fill: #ffffff; fill-opacity: 0.33;"></circle>',
  //   '<circle cx="918" cy="215" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="255" cy="396" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="305" cy="404" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="719" cy="71" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="570" cy="603" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="643" cy="565" r="1" style="fill: #ffffff; fill-opacity: 0.41;"></circle>',
  //   '<circle cx="258" cy="228" r="1" style="fill: #ffffff; fill-opacity: 0.34;"></circle>',
  //   '<circle cx="100" cy="824" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="981" cy="978" r="1" style="fill: #ffffff; fill-opacity: 0.33;"></circle>',
  //   '<circle cx="457" cy="291" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="433" cy="116" r="1" style="fill: #ffffff; fill-opacity: 0.19;"></circle>',
  //   '<circle cx="636" cy="777" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="878" cy="63" r="1" style="fill: #ffffff; fill-opacity: 0.16;"></circle>',
  //   '<circle cx="292" cy="47" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="190" cy="203" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="138" cy="751" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="453" cy="23" r="1" style="fill: #ffffff; fill-opacity: 0.22;"></circle>',
  //   '<circle cx="317" cy="333" r="1" style="fill: #ffffff; fill-opacity: 0.42;"></circle>',
  //   '<circle cx="171" cy="236" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="931" cy="84" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="402" cy="448" r="1" style="fill: #ffffff; fill-opacity: 0.22;"></circle>',
  //   '<circle cx="298" cy="125" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="10" cy="37" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="341" cy="190" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="244" cy="108" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="282" cy="283" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="591" cy="799" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="722" cy="907" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="69" cy="264" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="713" cy="770" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="154" cy="811" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="635" cy="495" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="302" cy="610" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="320" cy="156" r="1" style="fill: #ffffff; fill-opacity: 0.23;"></circle>',
  //   '<circle cx="746" cy="346" r="1" style="fill: #ffffff; fill-opacity: 0.44;"></circle>',
  //   '<circle cx="391" cy="967" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="780" cy="179" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="109" cy="46" r="1" style="fill: #ffffff; fill-opacity: 0.41;"></circle>',
  //   '<circle cx="856" cy="291" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="742" cy="769" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="839" cy="361" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="276" cy="344" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="487" cy="326" r="1" style="fill: #ffffff; fill-opacity: 0.2;"></circle>',
  //   '<circle cx="860" cy="740" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="93" cy="238" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="868" cy="474" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="563" cy="514" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="120" cy="681" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="735" cy="873" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="248" cy="759" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="297" cy="689" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="415" cy="920" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="59" cy="716" r="1" style="fill: #ffffff; fill-opacity: 0.35;"></circle>',
  //   '<circle cx="844" cy="215" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="225" cy="690" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="364" cy="362" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="550" cy="256" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="345" cy="479" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="292" cy="597" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="150" cy="247" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="999" cy="296" r="1" style="fill: #ffffff; fill-opacity: 0.34;"></circle>',
  //   '<circle cx="398" cy="455" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="903" cy="13" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="578" cy="394" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="443" cy="632" r="1" style="fill: #ffffff; fill-opacity: 0.36;"></circle>',
  //   '<circle cx="400" cy="642" r="1" style="fill: #ffffff; fill-opacity: 0.21;"></circle>',
  //   '<circle cx="400" cy="837" r="1" style="fill: #ffffff; fill-opacity: 0.15;"></circle>',
  //   '<circle cx="829" cy="593" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="51" cy="528" r="1" style="fill: #ffffff; fill-opacity: 0.42;"></circle>',
  //   '<circle cx="905" cy="849" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="146" cy="916" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="4" cy="673" r="1" style="fill: #ffffff; fill-opacity: 0.26;"></circle>',
  //   '<circle cx="403" cy="365" r="1" style="fill: #ffffff; fill-opacity: 0.2;"></circle>',
  //   '<circle cx="38" cy="673" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="592" cy="284" r="1" style="fill: #ffffff; fill-opacity: 0.16;"></circle>',
  //   '<circle cx="42" cy="555" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="610" cy="569" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="247" cy="588" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="135" cy="187" r="1" style="fill: #ffffff; fill-opacity: 0.37;"></circle>',
  //   '<circle cx="804" cy="666" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="356" cy="871" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="919" cy="394" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="442" cy="664" r="1" style="fill: #ffffff; fill-opacity: 0.18;"></circle>',
  //   '<circle cx="356" cy="147" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="16" cy="907" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="24" cy="547" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="803" cy="477" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="994" cy="905" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="477" cy="229" r="1" style="fill: #ffffff; fill-opacity: 0.2;"></circle>',
  //   '<circle cx="795" cy="70" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="444" cy="896" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="529" cy="86" r="1" style="fill: #ffffff; fill-opacity: 0.42;"></circle>',
  //   '<circle cx="564" cy="154" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="119" cy="883" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="370" cy="574" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="957" cy="662" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="907" cy="18" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="504" cy="144" r="1" style="fill: #ffffff; fill-opacity: 0.47;"></circle>',
  //   '<circle cx="461" cy="503" r="1" style="fill: #ffffff; fill-opacity: 0.23;"></circle>',
  //   '<circle cx="702" cy="138" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="505" cy="304" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="576" cy="794" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="338" cy="818" r="1" style="fill: #ffffff; fill-opacity: 0.31;"></circle>',
  //   '<circle cx="579" cy="350" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="90" cy="135" r="1" style="fill: #ffffff; fill-opacity: 0.2;"></circle>',
  //   '<circle cx="601" cy="664" r="1" style="fill: #ffffff; fill-opacity: 0.25;"></circle>',
  //   '<circle cx="678" cy="339" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="91" cy="557" r="1" style="fill: #ffffff; fill-opacity: 0.26;"></circle>',
  //   '<circle cx="530" cy="805" r="1" style="fill: #ffffff; fill-opacity: 0.22;"></circle>',
  //   '<circle cx="68" cy="599" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="868" cy="992" r="1" style="fill: #ffffff; fill-opacity: 0.21;"></circle>',
  //   '<circle cx="129" cy="763" r="1" style="fill: #ffffff; fill-opacity: 0.19;"></circle>',
  //   '<circle cx="97" cy="161" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="77" cy="816" r="1" style="fill: #ffffff; fill-opacity: 0.15;"></circle>',
  //   '<circle cx="271" cy="898" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="355" cy="19" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="351" cy="888" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="678" cy="807" r="1" style="fill: #ffffff; fill-opacity: 0.33;"></circle>',
  //   '<circle cx="782" cy="828" r="1" style="fill: #ffffff; fill-opacity: 0.21;"></circle>',
  //   '<circle cx="442" cy="280" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="148" cy="89" r="1" style="fill: #ffffff; fill-opacity: 0.44;"></circle>',
  //   '<circle cx="407" cy="706" r="1" style="fill: #ffffff; fill-opacity: 0.2;"></circle>',
  //   '<circle cx="600" cy="420" r="1" style="fill: #ffffff; fill-opacity: 0.36;"></circle>',
  //   '<circle cx="846" cy="912" r="1" style="fill: #ffffff; fill-opacity: 0.29;"></circle>',
  //   '<circle cx="340" cy="818" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="745" cy="931" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="526" cy="164" r="1" style="fill: #ffffff; fill-opacity: 0.19;"></circle>',
  //   '<circle cx="539" cy="877" r="1" style="fill: #ffffff; fill-opacity: 0.37;"></circle>',
  //   '<circle cx="420" cy="564" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="126" cy="357" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="389" cy="38" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="569" cy="380" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="291" cy="39" r="1" style="fill: #ffffff; fill-opacity: 0.34;"></circle>',
  //   '<circle cx="206" cy="61" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="55" cy="860" r="1" style="fill: #ffffff; fill-opacity: 0.37;"></circle>',
  //   '<circle cx="206" cy="160" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="950" cy="394" r="1" style="fill: #ffffff; fill-opacity: 0.3;"></circle>',
  //   '<circle cx="535" cy="678" r="1" style="fill: #ffffff; fill-opacity: 0.32;"></circle>',
  //   '<circle cx="10" cy="480" r="1" style="fill: #ffffff; fill-opacity: 0.45;"></circle>',
  //   '<circle cx="423" cy="636" r="1" style="fill: #ffffff; fill-opacity: 0.44;"></circle>',
  //   '<circle cx="11" cy="708" r="1" style="fill: #ffffff; fill-opacity: 0.16;"></circle>',
  //   '<circle cx="584" cy="699" r="1" style="fill: #ffffff; fill-opacity: 0.15;"></circle>',
  //   '<circle cx="605" cy="679" r="1" style="fill: #ffffff; fill-opacity: 0.46;"></circle>',
  //   '<circle cx="453" cy="452" r="1" style="fill: #ffffff; fill-opacity: 0.4;"></circle>',
  //   '<circle cx="650" cy="351" r="1" style="fill: #ffffff; fill-opacity: 0.42;"></circle>',
  //   '<circle cx="556" cy="988" r="1" style="fill: #ffffff; fill-opacity: 0.15;"></circle>',
  //   '<circle cx="317" cy="11" r="1" style="fill: #ffffff; fill-opacity: 0.19;"></circle>',
  //   '<circle cx="654" cy="72" r="1" style="fill: #ffffff; fill-opacity: 0.28;"></circle>',
  //   '<circle cx="195" cy="505" r="1" style="fill: #ffffff; fill-opacity: 0.24;"></circle>',
  //   '<circle cx="659" cy="727" r="1" style="fill: #ffffff; fill-opacity: 0.43;"></circle>',
  //   '<circle cx="410" cy="337" r="1" style="fill: #ffffff; fill-opacity: 0.48;"></circle>',
  //   '<circle cx="547" cy="731" r="1" style="fill: #ffffff; fill-opacity: 0.49;"></circle>',
  //   '<circle cx="246" cy="457" r="1" style="fill: #ffffff; fill-opacity: 0.26;"></circle>',
  //   '<circle cx="893" cy="759" r="1" style="fill: #ffffff; fill-opacity: 0.38;"></circle>',
  //   '<circle cx="61" cy="187" r="1" style="fill: #ffffff; fill-opacity: 0.47;"></circle>',
  //   '<circle cx="18" cy="953" r="1" style="fill: #ffffff; fill-opacity: 0.39;"></circle>',
  //   '<circle cx="456" cy="155" r="1" style="fill: #ffffff; fill-opacity: 0.23;"></circle>',
  //   '<circle cx="792" cy="184" r="1" style="fill: #ffffff; fill-opacity: 0.27;"></circle>',
  //   '<circle cx="917" cy="826" r="1" style="fill: #ffffff; fill-opacity: 0.17;"></circle>',
  //   '<circle cx="967" cy="77" r="1" style="fill: #ffffff; fill-opacity: 0.3;"></circle>',
  //   '<circle cx="974" cy="174" r="1" style="fill: #ffffff; fill-opacity: 0.16;"></circle>'
  // ));
}