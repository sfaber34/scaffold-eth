// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './Trigonometry.sol';
import './Structs.sol';
import './HexStrings.sol';
import './Uint2Str.sol';
import './ToColor.sol';
import "hardhat/console.sol";

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

// custom errors save gas
error INSUFFICIENT_AMOUNT();
error TOKEN_TRANSFER_FAILURE();
error REFUND_TRANSFER_FAILURE();
error INVALID_ID();

contract YourCollectible is ERC721Enumerable, ReentrancyGuard, Ownable {

  using Strings for uint256;
  using Uint2Str for uint8;
  using Uint2Str for uint16;
  using Uint2Str for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string[17] public resourceList = [
    '', 'Hydrogen', 'Ammonia', 'Methane', 
    'Aluminium', 'Iron', 'Nickel', 'Copper',
    'Silicon', 'Gold', 'Titanium', 'Lithium',
    'Cobalt', 'Platinum', 'Chromium', 'Terbium',
    'Selenium'
  ];

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
      nonReentrant
      returns (uint256)
  {   
      // avoid an extra SLOAD to save gas
      uint _price = price;
      console.log("_price: %s", _price);

      uint priceFuture = (_price * curve * curve) / 1000;
      console.log("priceFuture: %s", priceFuture);

      if (msg.value < _price) {
         revert INSUFFICIENT_AMOUNT();
      }

      price = (_price * curve) / 1000;
      console.log("price: %s", price);

      uint256 id = _tokenIds.current();
      randomish[id] = keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), id ));

      _mint(msg.sender, id);

      _tokenIds.increment();

      (bool mintFeeSent, ) = recipient.call{value: msg.value}("");
      if (!mintFeeSent) {
        revert TOKEN_TRANSFER_FAILURE();
      }

      uint256 refund = msg.value - _price;
      console.log("refund: %s", refund);
      if (refund > 0) {
        (bool refundSent, ) = payable(msg.sender).call{value: refund}("");
        if (!refundSent) {
          revert REFUND_TRANSFER_FAILURE();
        }
      }
      
      return id;
  }

  function getTokenURI(uint256 id, bool transparentBackground) public view returns (string memory uri){
    if(!_exists(id)) {
      revert INVALID_ID();
    }

    (Structs.System memory system, Structs.Planet[] memory planets) = IPopulateSystemLayoutStructs(populateSystemLayoutStructsAddress).populateSystemLayoutStructs(randomish[id]);
    
    string memory description = string(abi.encodePacked(
      system.name,
      ' is a ',
      system.category,
      ' star with ', 
      planets.length.uint2Str(),
      ' planets located at ',
      system.coordinates[0].uint2Str(),', ',system.coordinates[1].uint2Str()
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
  

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderToken(Structs.System memory system, Structs.Planet[] memory planets) public view returns (string memory) {
    string memory render = IReturnSystemSvg(returnSystemSvgAddress).returnSystemSvg(system, planets);
    
    return render;
  }

  function populateNFTAttributes(Structs.System memory system, Structs.Planet[] memory planets) internal view returns (bytes memory attributes) {
    string memory topResource = getTopResource(planets);

    attributes = abi.encodePacked(
      '"attributes": [{"trait_type": "system_coordinates", "value": "',
      system.coordinates[0].uint2Str(),', ',system.coordinates[1].uint2Str(),
      '"},{"trait_type": "star_type", "value": "',
      system.category,
      '"},{"trait_type": "planet_count", "value": "',
      planets.length.uint2Str(),
      '"},{"trait_type": "habitable_world_count", "value": "',
      system.nHabitable.uint2Str(),
      '"},{"trait_type": "rocky_planet_count", "value": "',
      system.nRocky.uint2Str(),
      '"},{"trait_type": "gas_giant_count", "value": "',
      system.nGas.uint2Str(),
      '"},{"trait_type": "top_resource", "value": "',
      topResource,
      '"}],'
    );

    return attributes;
  }

  function getTopResource(Structs.Planet[] memory planets) public view returns (string memory topResource) {
    uint8 topResourceCode;

    for (uint i=0; i<planets.length;) {
      for (uint j=0; j<3;) {
        if(planets[i].resources[j] > topResourceCode) {
          topResourceCode = planets[i].resources[j];
        }
        unchecked { ++ j; }
      }
      unchecked { ++ i; }
    }

    return resourceList[topResourceCode];
  }
}
