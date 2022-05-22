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
    string sector; // Just used for nft attributes, mainly to draw text in bottom svg corners
    uint16 sectorI;
    uint16 radius; // Star radius (pixels)
    uint16 colorH;
    address owner;
    uint256[] planets; // stores ids of planets in each system
  }

}