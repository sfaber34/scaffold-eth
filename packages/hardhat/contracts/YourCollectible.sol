// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './Trigonometry.sol';
import './Structs.sol';
import './HexStrings.sol';
import './Uint2Str.sol';
import './ToColor.sol';


interface IReturnSystemSvg {
  function returnSystemSvg(
    Structs.System memory system,
    Structs.Planet[] memory planets
  ) external pure returns (
    string memory
  );
}

interface ISystemName {
  function generateSystemName(uint256 id) external pure returns (string memory);
}

interface ISystemData {
  function getStarRadius(uint256 id) external pure returns (uint16);
  function getStarCategory(uint16 starRadius) external pure returns (string memory);
  function getStarHue(uint256 id, uint16 starRadius) external pure returns (uint16);
  function getPlanetRadii(uint256 id, uint16 nPlanets) external pure returns (uint16[] memory);
  function getPlanetOrbitDistance(uint16 starRadius, uint16[] memory plRadii) external pure returns (uint16[] memory);
  function getPlanetCategories(uint16[] memory plRadii, uint16[] memory plOrbDist) external pure returns (uint8[] memory);
  function getNPlanets(uint256 id) external pure returns (uint16);
  function getPlanetHues(uint256 id, uint256 index, uint8 plCategory) external pure returns (uint16[5] memory);
  function getPlanetTurbScale(uint256 id, uint256 index, uint8 plCategory) external pure returns (uint16);
}

contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using Uint2Str for uint16;
  using Uint2Str for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // all funds go to buidlguidl.eth
  address payable public constant recipient = payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

  uint256 public constant limit = 512;
  uint256 public constant curve = 1011;
  uint256 public price = 0.01 ether;
  // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

  address public structsAddress;
  address public systemDataAddress;
  address public systemNameAddress;
  address public returnSystemSvgAddress;
  constructor(
    address _structsAddress,
    address _systemDataAddress,
    address _systemNameAddress,
    address _returnSystemSvgAddress
  ) ERC721("Exos", "EXOS") {
    structsAddress = _structsAddress;
    systemDataAddress = _systemDataAddress;
    systemNameAddress = _systemNameAddress;
    returnSystemSvgAddress = _returnSystemSvgAddress;
  } 

  function mintItem()
      public
      payable
      returns (uint256)
  {
      // require(_tokenIds.current() < limit, "DONE MINTING");
      require(totalSupply() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");
      
      price = (price * curve) / 1000;

      // uint256 id = _tokenIds.current();
      uint256 id = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), msg.value, block.timestamp )));

      _mint(msg.sender, id);

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      // _tokenIds.increment();
      
      return id;
  }
  
  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");

      // (Structs.System memory system, Structs.Planet[] memory planets) = SystemData.generateSystemData(id);
      
      string memory description = string(abi.encodePacked(
        // system.name,
        'foo',
        ' is a ',
        // system.category,
        'foo',
        ' star with ', 
        // planets.length.uint2Str(),
        'foo',
        ' planets.'
      ));

      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              // system.name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://foo.com/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "star_type", "value": "',
                              // system.category,
                              'foo',
                              '"},{"trait_type": "planet_count", "value": "',
                              // planets.length.uint2Str(),
                              'foo',
                              '"}], "owner":"',
                              // (uint160(ownerOf(id))).toHexString(20),
                              'foo',
                              '", "image": "',
                              'data:image/svg+xml;base64,',
                              image,
                              '"}'
                          )
                        )
                    )
              )
          );
  }

                              //   '", "attributes": [{"trait_type": "color", "value": "#',
                              // color[id].toColor(),
                              // '"},{"trait_type": "chubbiness", "value": ',
                              // uint2str(chubbiness[id]),
                              // '}], "owner":"',

  function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="1000" height="1000" style="background: #000000;" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    (Structs.System memory system, Structs.Planet[] memory planets) = populateSystemLayoutData(id);
    // string memory render = system.returnSystemSvg(planets);
    string memory render = IReturnSystemSvg(returnSystemSvgAddress).returnSystemSvg(system, planets);
    
    return render;
  }

  function populateSystemLayoutData(uint256 id) public view returns (Structs.System memory system, Structs.Planet[] memory) {
    system.name = ISystemName(systemNameAddress).generateSystemName(id);

    system.radius = ISystemData(systemDataAddress).getStarRadius(id);
    system.hue = ISystemData(systemDataAddress).getStarHue(id, system.radius);
    system.category = ISystemData(systemDataAddress).getStarCategory(system.radius);

    uint16 nPlanets = ISystemData(systemDataAddress).getNPlanets(id);
    uint16[] memory plRadii = ISystemData(systemDataAddress).getPlanetRadii(id, nPlanets);
    uint16[] memory plOrbDist = ISystemData(systemDataAddress).getPlanetOrbitDistance(system.radius, plRadii);
    uint8[] memory plCategory = ISystemData(systemDataAddress).getPlanetCategories(plRadii, plOrbDist);
    
    Structs.Planet[] memory planets = new Structs.Planet[] (plRadii.length);

    for (uint i=0; i<plRadii.length; i++) {
      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].category = plCategory[i];

      uint16[5] memory plHues = ISystemData(systemDataAddress).getPlanetHues(id, i, plCategory[i]);
      uint16 turbScale = ISystemData(systemDataAddress).getPlanetTurbScale(id, i, plCategory[i]);

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
