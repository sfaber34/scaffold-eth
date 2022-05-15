// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {

  struct Planet {
    uint8 radius; // pixels
    uint16 orbDist; // pixels
    string colorA; // Base planet color
    string colorB; // Secondary planet color
    string colorC; // Tertiary planet color
  }

  struct System {
    string name; // Just used for nft attributes, mainly to draw text in bottom svg corners
    uint16 distToSol; // Similiar to name. Not used in layout logic or anything
    uint8 radius; // star radius in pixels
    string color; // star color
    address owner;
    uint256[] planets; // stores ids of planets in each system
  }

}