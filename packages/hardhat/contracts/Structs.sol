// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Structs {
  
  // since string will take up 1 slot so with this order the total slots consumed by the struct are 3 instead of 4
  struct System {
    string name; // The system/star name. Looks something like "Sigma Leviathan Sector-a4504d"
    string category; // Star type. Can be "Blue Dwarf", "Main Sequence", or "Red Giant"
    bytes32 entropy; // keccak256 output for future use 
    uint16[2] coordinates; // Galactic x/y system coordinates. Ranges 1 to 65535.
    uint16 radius; // Star radius (pixels)
    uint16 hue; // Star Hue
    uint8 nGas; // Number of gas planets
    uint8 nRocky; // Number of rocky, mars-like worlds
    uint8 nHabitable; // Number of habitable, earth-like worlds
  }

  struct Planet {
    bytes32 entropy; // keccak256 output for future use 
    uint16 radius; // Planet radius (pixels)
    uint16 orbDist; // Planet orbit distance; radial distance from star centroid to planet centroid (pixels) 
    uint16 hueA; // Base planet hue
    uint16 hueB; // Secondary planet hue
    uint16 hueC; // Tertiary planet hue
    uint16 hueD; // You get it...
    uint16 hueE;
    uint16 turbScale; // Smear filter turbulance scale. Adds more variation in planet appearance
    uint8 category; // Planet type. Can be Gas Giant, Rocky (like mars), or Habitable (like earth)
    uint8[3] resources; // Each planet gets 1 to 3 resources for mining. See getPlanetResources() in PopulateSystemLayoutStructs.sol for resource types.
    uint8[3] resourceAbundance; // Each resource gets an abundance metric ranging 1 to 100.
  }
}