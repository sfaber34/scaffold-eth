// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Structs.sol';

interface ISystemName {
  function generateSystemName(bytes32 randomish) external pure returns (string memory);
}

interface ISystemData {
  function getStarRadius(bytes32 randomish) external pure returns (uint16);
  function getStarCategory(uint16 starRadius) external pure returns (string memory);
  function getStarHue(bytes32 randomish, uint16 starRadius) external pure returns (uint16);
  function getPlanetRadii(bytes32 randomish, uint16 nPlanets) external pure returns (uint16[] memory);
  function getPlanetOrbitDistance(uint16 starRadius, uint16[] memory plRadii) external pure returns (uint16[] memory);
  function getPlanetCategories(uint16[] memory plRadii, uint16[] memory plOrbDist, uint16 starRadius) external pure returns (uint8[] memory);
  function getNPlanets(bytes32 randomish) external pure returns (uint16);
  function getPlanetHues(bytes32 randomish, uint256 index, uint8 plCategory) external pure returns (uint16[5] memory);
  function getPlanetTurbScale(bytes32 randomish, uint256 index, uint8 plCategory) external pure returns (uint16);
  function getPlanetCategoriesCounts(uint8[] memory plCategory) external pure returns (uint8 nGas, uint8 nRocky, uint8 nHabitable);
}

contract PopulateSystemLayoutStructs {

  address public structsAddress;
  address public systemDataAddress;
  address public systemNameAddress;
  constructor(
    address _structsAddress,
    address _systemDataAddress,
    address _systemNameAddress
  ) {
    structsAddress = _structsAddress;
    systemDataAddress = _systemDataAddress;
    systemNameAddress = _systemNameAddress;
  } 

  function populateSystemLayoutStructs(bytes32 randomish) external view returns (Structs.System memory system, Structs.Planet[] memory) {
    system.name = ISystemName(systemNameAddress).generateSystemName(randomish);

    system.radius = ISystemData(systemDataAddress).getStarRadius(randomish);
    system.hue = ISystemData(systemDataAddress).getStarHue(randomish, system.radius);
    system.category = ISystemData(systemDataAddress).getStarCategory(system.radius);

    uint16 nPlanets = ISystemData(systemDataAddress).getNPlanets(randomish);
    uint16[] memory plRadii = ISystemData(systemDataAddress).getPlanetRadii(randomish, nPlanets);
    uint16[] memory plOrbDist = ISystemData(systemDataAddress).getPlanetOrbitDistance(system.radius, plRadii);
    uint8[] memory plCategory = ISystemData(systemDataAddress).getPlanetCategories(plRadii, plOrbDist, system.radius);

    (uint8 nGas, uint8 nRocky, uint8 nHabitable) = ISystemData(systemDataAddress).getPlanetCategoriesCounts(plCategory);
    system.nGas = nGas;
    system.nRocky = nRocky;
    system.nHabitable = nHabitable;
    
    Structs.Planet[] memory planets = new Structs.Planet[] (plRadii.length);

    for (uint i=0; i<plRadii.length; i++) {
      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].category = plCategory[i];

      uint16[5] memory plHues = ISystemData(systemDataAddress).getPlanetHues(randomish, i, plCategory[i]);
      uint16 turbScale = ISystemData(systemDataAddress).getPlanetTurbScale(randomish, i, plCategory[i]);

      planets[i].turbScale = turbScale;
      planets[i].hueA = plHues[0];
      planets[i].hueB = plHues[1];
      planets[i].hueC = plHues[2];
      planets[i].hueD = plHues[3];
      planets[i].hueE = plHues[4];
    }

    return (system, planets);
  }

}