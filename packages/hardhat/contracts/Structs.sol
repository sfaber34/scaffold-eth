// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {

  struct System {
    string name; // The system/star name
    uint8[2] coordinates;
    uint16 radius; // Star radius (pixels)
    uint16 hue; // Star Hue
    string category; // Star type: main sequence or dwarf
    uint8 nGas;
    uint8 nRocky;
    uint8 nHabitable;  
  }

  struct Planet {
    uint16 radius; // Planet radius (pixels)
    uint16 orbDist; // Planet orbit distance; radial distance from star centroid to planet centroid (pixels)
    uint8 category;
    uint16 hueA; // Base planet hue
    uint16 hueB; // Secondary planet hue
    uint16 hueC; // Tertiary planet hue
    uint16 hueD; // You get it...
    uint16 hueE;
    uint16 turbScale; // Smear filter turbulance scale. Adds more variation in planet appearance
  }

}