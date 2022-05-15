// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {

  struct Planet {
    uint8 radius; // Planet radius (pixels)
    uint16 orbDist; // Planet orbit distance; radial distance from star centroid to planet centroid (pixels)
    string colorA; // Base planet color (hex)
    string colorB; // Secondary planet color (hex)
    string colorC; // Tertiary planet color (hex)
  }

  struct System {
    string name; // Just used for nft attributes, mainly to draw text in bottom svg corners
    uint16 distToSol; // Similiar to name. Not used in layout logic or anything
    uint8 radius; // Star radius (pixels)
    string color; // Star color (hex)
    address owner;
    uint256[] planets; // stores ids of planets in each system
  }

}