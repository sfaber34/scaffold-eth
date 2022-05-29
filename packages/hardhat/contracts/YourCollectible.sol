// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './HexStrings.sol';
import './ToColor.sol';
import './Uint2Str.sol';
import './ReturnSvg.sol';
import './Trigonometry.sol';

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two


contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using Uint2Str for uint16;
  using Uint2Str for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using ReturnSvg for uint256;
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // all funds go to buidlguidl.eth
  address payable public constant recipient = payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

  uint256 public constant limit = 512;
  uint256 public constant curve = 1011;
  uint256 public price = 0.01 ether;
  // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

  address public systemDataAddress;
  
  constructor(address _systemDataAddress) ERC721("Exos", "EXOS") {
    systemDataAddress = _systemDataAddress;
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
      uint256 id = uint256(keccak256(abi.encodePacked( blockhash(block.number-1), msg.sender, address(this), block.timestamp )));

      _mint(msg.sender, id);

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      // _tokenIds.increment();
      
      return id;
  }
  
  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");

      (Structs.System memory system, Structs.Planet[] memory planets) = ISystemData(systemDataAddress).createSystem(id);
      
      string memory description = string(abi.encodePacked(
        system.name,
        ' is a ',
        system.sequence,
        ' star with ', 
        planets.length.uint2Str(),
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
                              system.sequence,
                              '"},{"trait_type": "planet_count", "value": "',
                              planets.length.uint2Str(),
                              '"}], "owner":"',
                              (uint160(ownerOf(id))).toHexString(20),
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
    string memory render = id.returnSvg(systemDataAddress);
    
    return render;
  }

}
