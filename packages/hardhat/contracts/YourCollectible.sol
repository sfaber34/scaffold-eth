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


interface IPopulateSystemLayoutStructs {
  
  function populateSystemLayoutStructs(
    bytes32 randomish
  ) external view returns (
    Structs.System memory system, Structs.Planet[] memory
  );
  
}

interface IReturnSystemSvg {

  function returnSystemSvg(
    Structs.System memory system,
    Structs.Planet[] memory planets
  ) external pure returns (
    string memory
  );

}

contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using Uint2Str for uint8;
  using Uint2Str for uint16;
  using Uint2Str for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // Funds to Exos treasury 
  address payable public constant recipient = payable(0x859a0ef4b9D689623C8a83e7eEe7799Fa091976b);

  uint256 public constant curve = 1011;
  uint256 public price = 0.005 ether;

  mapping (uint256 => bytes32) public randomish;

  address public populateSystemLayoutStructsAddress;
  address public returnSystemSvgAddress;
  constructor(
    address _populateSystemLayoutStructsAddress,
    address _returnSystemSvgAddress
  ) ERC721("Exos", "EXOS") {
    populateSystemLayoutStructsAddress = _populateSystemLayoutStructsAddress;
    returnSystemSvgAddress = _returnSystemSvgAddress;
  } 

  function updatePopulateSystemLayoutStructsAddress(address newAddress) public onlyOwner {
    populateSystemLayoutStructsAddress = newAddress;
  } 

  function updateReturnSystemSvgAddress(address newAddress) public onlyOwner {
    returnSystemSvgAddress = newAddress;
  }

  function mintItem()
      public
      payable
      returns (uint256)
  {
      require(msg.value >= price, "NOT ENOUGH");
      
      price = (price * curve) / 1000;

      uint256 id = _tokenIds.current();
      randomish[id] = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));

      _mint(msg.sender, id);

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      _tokenIds.increment();
      
      return id;
  }

  function getTokenURI(uint256 id, bool transparentBackground) public view returns (string memory uri){
    require(_exists(id), "not exist");

    (Structs.System memory system, Structs.Planet[] memory planets) = IPopulateSystemLayoutStructs(populateSystemLayoutStructsAddress).populateSystemLayoutStructs(randomish[id]);
    
    string memory description = string(abi.encodePacked(
      system.name,
      ' is a ',
      system.category,
      ' star with ', 
      planets.length.uint2Str(),
      ' planets.'
    ));

    string memory image = generateSVGofToken(system, planets, transparentBackground);
    bytes memory attributes = populateNFTAttributes(system, planets);

    uri = string(
      abi.encodePacked(
        'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                  '{"name":"',
                  system.name,
                  '", "description":"',
                  description,
                  '", "external_url":"https://foo.com/',
                  id.toString(),
                  '", ',
                  attributes,
                  ' "owner":"',
                  (uint160(ownerOf(id))).toHexString(20),
                  '", "image": "',
                  image,
                  '"}'
                  )
                )
              )
            )
        );


    return uri;
  }

  function tokenURI(uint256 id) public view override returns (string memory uri) {
    return getTokenURI(id, false);
  }

  function generateSVGofToken(Structs.System memory system, Structs.Planet[] memory planets, bool transparentBackground) internal view returns (string memory svg) {

    svg = string(abi.encodePacked(
      'data:image/svg+xml;base64,',
      Base64.encode(bytes(abi.encodePacked(
        '<svg width="1000" height="1000" style="background: ',
        transparentBackground ? '#00000000;' : '#000000;',
        '" xmlns="http://www.w3.org/2000/svg">',
          renderToken(system, planets),
        '</svg>'
      )))
    ));

    

    return svg;
  }
  
  // function tokenURI(uint256 id) public view override returns (string memory) {
  //     require(_exists(id), "not exist");

  //     (Structs.System memory system, Structs.Planet[] memory planets) = IPopulateSystemLayoutStructs(populateSystemLayoutStructsAddress).populateSystemLayoutStructs(randomish[id]);
      
  //     string memory description = string(abi.encodePacked(
  //       system.name,
  //       ' is a ',
  //       system.category,
  //       ' star with ', 
  //       planets.length.uint2Str(),
  //       ' planets.'
  //     ));

  //     string memory image = Base64.encode(bytes(generateSVGofToken(system, planets)));
  //     bytes memory attributes = populateNFTAttributes(system, planets);

  //     return
  //         string(
  //             abi.encodePacked(
  //               'data:application/json;base64,',
  //               Base64.encode(
  //                   bytes(
  //                         abi.encodePacked(
  //                             '{"name":"',
  //                             system.name,
  //                             '", "description":"',
  //                             description,
  //                             '", "external_url":"https://foo.com/',
  //                             id.toString(),
  //                             '", ',
  //                             attributes,
  //                             ' "owner":"',
  //                             (uint160(ownerOf(id))).toHexString(20),
  //                             '", "image": "',
  //                             'data:image/svg+xml;base64,',
  //                             image,
  //                             '"}'
  //                         )
  //                       )
  //                   )
  //             )
  //         );
  // }

  // function generateSVGofToken(Structs.System memory system, Structs.Planet[] memory planets) internal view returns (string memory) {

  //   string memory svg = string(abi.encodePacked(
  //     '<svg width="1000" height="1000" style="background: #000000;" xmlns="http://www.w3.org/2000/svg">',
  //       renderToken(system, planets),
  //     '</svg>'
  //   ));

  //   return svg;
  // }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderToken(Structs.System memory system, Structs.Planet[] memory planets) public view returns (string memory) {

    string memory render = IReturnSystemSvg(returnSystemSvgAddress).returnSystemSvg(system, planets);
    
    return render;
  }

  function populateNFTAttributes(Structs.System memory system, Structs.Planet[] memory planets) internal pure returns (bytes memory attributes) {

    attributes = abi.encodePacked(
      '"attributes": [{"trait_type": "star_type", "value": "',
      system.category,
      '"},{"trait_type": "planets", "value": "',
      planets.length.uint2Str(),
      '"},{"trait_type": "habitable_world_count", "value": "',
      system.nHabitable.uint2Str(),
      '"},{"trait_type": "rocky_planet_count", "value": "',
      system.nRocky.uint2Str(),
      '"},{"trait_type": "gas_giant_count", "value": "',
      system.nGas.uint2Str(),
      '"}],'
    );

    return attributes;
  }

  // function generateSVGofTokenById(uint256 id) internal view returns (string memory) {

  //   string memory svg = string(abi.encodePacked(
  //     '<svg width="1000" height="1000" style="background: #000000;" xmlns="http://www.w3.org/2000/svg">',
  //       renderTokenById(id),
  //     '</svg>'
  //   ));

  //   return svg;
  // }

  // // Visibility is `public` to enable it being called by other contracts for composition.
  // function renderTokenById(uint256 id) public view returns (string memory) {
  //   (Structs.System memory system, Structs.Planet[] memory planets) = IPopulateSystemLayoutStructs(populateSystemLayoutStructsAddress).populateSystemLayoutStructs(randomish[id]);
  //   // string memory render = system.returnSystemSvg(planets);
  //   string memory render = IReturnSystemSvg(returnSystemSvgAddress).returnSystemSvg(system, planets);
    
  //   return render;
  // }

}
