// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './HexStrings.sol';
import './Uint2Str.sol';
import './ToColor.sol';
import './SystemData.sol';
import './SystemName.sol';
import './ReturnSvg.sol';

contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using Uint2Str for uint16;
  using Uint2Str for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using ReturnSvg for Structs.System;
  using SystemName for uint256;
  using SystemData for uint16;
  using SystemData for uint256;
  using SystemData for uint16[];
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // all funds go to buidlguidl.eth
  address payable public constant recipient = payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

  uint256 public constant limit = 512;
  uint256 public constant curve = 1011;
  uint256 public price = 0.01 ether;
  // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

  constructor() ERC721("Exos", "EXOS") {} 

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

  function generateSVGofTokenById(uint256 id) internal pure returns (string memory) {

    string memory svg = string(abi.encodePacked(
      '<svg width="1000" height="1000" style="background: #000000;" xmlns="http://www.w3.org/2000/svg">',
        renderTokenById(id),
      '</svg>'
    ));

    return svg;
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public pure returns (string memory) {
    (Structs.System memory system, Structs.Planet[] memory planets) = generateSystemLayoutData(id);
    string memory render = system.returnSvg(planets);
    
    return render;
  }

  function generateSystemLayoutData(uint256 id) public pure returns (Structs.System memory system, Structs.Planet[] memory) {
    system.name = id.generateSystemName();

    system.radius = id.getStarRadius();
    system.hue = id.getStarHue(system.radius);
    system.category = system.radius.getStarCategory();

    uint16 nPlanets = id.getNPlanets();
    uint16[] memory plRadii = id.getPlanetRadii(nPlanets);
    uint16[] memory plOrbDist = system.radius.getPlanetOrbitDistance(plRadii);
    uint8[] memory plCategory = plRadii.getPlanetCategories(plOrbDist);
    
    Structs.Planet[] memory planets = new Structs.Planet[] (plRadii.length);

    for (uint i=0; i<plRadii.length; i++) {
      planets[i].radius = plRadii[i];
      planets[i].orbDist = plOrbDist[i];
      planets[i].category = plCategory[i];

      uint16[5] memory plHues = id.getPlanetHues(i, plCategory[i]);
      uint16 turbScale = id.getPlanetTurbScale(i, plCategory[i]);

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
