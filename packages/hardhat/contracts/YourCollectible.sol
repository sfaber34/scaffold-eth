// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import './HexStrings.sol';
import './ToColor.sol';
import './ReturnSvg.sol';
import './Trigonometry.sol';

//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using ReturnSvg for uint256;
  using Trigonometry for uint256;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // all funds go to buidlguidl.eth
  address payable public constant recipient =
    payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

  uint256 public constant limit = 11;
  uint256 public constant curve = 1002; // price increase 0,4% with each purchase
  uint256 public price = 0.001 ether;
  // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

  address public systemDataAddress;
  
    constructor(address _systemDataAddress) ERC721("Exos", "EXOS") {
    systemDataAddress = _systemDataAddress;
  } 

  // I didn't mess with the price curve here. It's still set up for minting ~2000 Loogies.
  function mintItem()
      public
      payable
      returns (uint256)
  {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");
      
      price = (price * curve) / 1000;

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      _tokenIds.increment();
      
      return id;
  }
  
  // This needs work. Just hacked it enough to get it drawing svgs.
  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");

      Structs.System memory system = ISystemData(systemDataAddress).getSystem(id);
      
      string memory description = string(abi.encodePacked(system.name , ' is ', uint2str(system.distToSol), ' ly from Sol.'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
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
                              '", "attributes": [{"trait_type": "star_color", "value": "',
                              system.color,
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

  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
      if (_i == 0) {
          return "0";
      }
      uint j = _i;
      uint len;
      while (j != 0) {
          len++;
          j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len;
      while (_i != 0) {
          k = k-1;
          uint8 temp = (48 + uint8(_i - _i / 10 * 10));
          bytes1 b1 = bytes1(temp);
          bstr[k] = b1;
          _i /= 10;
      }
      return string(bstr);
  }
}
