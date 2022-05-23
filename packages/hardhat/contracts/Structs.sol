// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {

  struct Planet {
    uint16 radius; // Planet radius (pixels)
    uint16 orbDist; // Planet orbit distance; radial distance from star centroid to planet centroid (pixels)
    string colorA; // Base planet color (hex)
    string colorB; // Secondary planet color (hex)
    string colorC; // Tertiary planet color (hex)
  }

  struct System {
    string sector; // The system parent name (randomly picked from string[20] internal sectors in SystemData.sol)
    uint16 sectorI; // Index of system in sector. Just counts up currently
    uint16 radius; // Star radius (pixels)
    uint16 colorH; // Star Hue
    address owner;
    uint256[] planets; // stores ids of planets in each system
  }

}