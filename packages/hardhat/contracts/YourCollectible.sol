pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import './HexStrings.sol';
import './ToColor.sol';
// import './Trigonometry.sol';
import 'hardhat/console.sol';
//learn more: https://docs.openzeppelin.com/contracts/3.x/erc721

// GET LISTED ON OPENSEA: https://testnets.opensea.io/get-listed/step-two

contract YourCollectible is ERC721Enumerable, Ownable {

  using Strings for uint256;
  using HexStrings for uint160;
  using ToColor for bytes3;
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // all funds go to buidlguidl.eth
  address payable public constant recipient =
    payable(0xa81a6a910FeD20374361B35C451a4a44F86CeD46);

  uint256 public constant limit = 3728;
  uint256 public constant curve = 1002; // price increase 0,4% with each purchase
  uint256 public price = 0.001 ether;
  // the 1154th optimistic loogies cost 0.01 ETH, the 2306th cost 0.1ETH, the 3459th cost 1 ETH and the last ones cost 1.7 ETH

  mapping (uint256 => bytes3) public color;
  mapping (uint256 => uint256) public chubbiness;
  mapping (uint256 => uint256) public mouthLength;

  event PassArray(string arrayName, uint256[] array);

  constructor() public ERC721("OptimisticLoogies", "OPLOOG") {
    // RELEASE THE OPTIMISTIC LOOGIES!
  }
  
  // string public json = '{"hostname":{"0":"tau Cet","1":"rho CrB"},"st_rad":{"0":577968,"1":947032},"st_teff_k":{"0":5310,"1":5627},"sy_dist":{"0":12,"1":57},"pl_rad":{"0":[11532,11532,7518,7581],"1":[87920,34276]},"pl_orbsmax":{"0":[80483655,199563560,19896517,36352283],"1":[32851692,61679202]}}';

  function mintItem()
      public
      payable
      returns (uint256)
  {
      require(_tokenIds.current() < limit, "DONE MINTING");
      require(msg.value >= price, "NOT ENOUGH");

      price = (price * curve) / 1000;

      _tokenIds.increment();

      uint256 id = _tokenIds.current();
      _mint(msg.sender, id);

      bytes32 predictableRandom = keccak256(abi.encodePacked( id, blockhash(block.number-1), msg.sender, address(this) ));
      color[id] = bytes2(predictableRandom[0]) | ( bytes2(predictableRandom[1]) >> 8 ) | ( bytes3(predictableRandom[2]) >> 16 );
      chubbiness[id] = 35+((55*uint256(uint8(predictableRandom[3])))/255);
      // small chubiness loogies have small mouth
      mouthLength[id] = 180+((uint256(chubbiness[id]/4)*uint256(uint8(predictableRandom[4])))/255);

      (bool success, ) = recipient.call{value: msg.value}("");
      require(success, "could not send");

      return id;
  }

  function tokenURI(uint256 id) public view override returns (string memory) {
      require(_exists(id), "not exist");
      string memory name = string(abi.encodePacked('Loogie #',id.toString()));
      string memory description = string(abi.encodePacked('This Loogie is the color #',color[id].toColor(),' with a chubbiness of ',uint2str(chubbiness[id]),' and mouth length of ',uint2str(mouthLength[id]),'!!!'));
      string memory image = Base64.encode(bytes(generateSVGofTokenById(id)));

      return
          string(
              abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                          abi.encodePacked(
                              '{"name":"',
                              name,
                              '", "description":"',
                              description,
                              '", "external_url":"https://burnyboys.com/token/',
                              id.toString(),
                              '", "attributes": [{"trait_type": "color", "value": "#',
                              color[id].toColor(),
                              '"},{"trait_type": "chubbiness", "value": ',
                              uint2str(chubbiness[id]),
                              '},{"trait_type": "mouthLength", "value": ',
                              uint2str(mouthLength[id]),
                              '}], "owner":"',
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

  function max(uint256[] memory numbers) public returns (uint256) {
    require(numbers.length > 0); // throw an exception if the condition is not met
    uint256 maxNumber; // default 0, the lowest value of `uint256`

    for (uint256 i = 0; i < numbers.length; i++) {
        if (numbers[i] > maxNumber) {
            maxNumber = numbers[i];
        }
    }

    return maxNumber;
}

  // uint256[4] planetR = [11532, 11532, 7518, 7581];
  // uint256[] memory planetR = new uint256[](4);
  uint256 public maxPlanetOrb;
  uint256 public sinTest = 0;
  function calculateLayout(uint256 id) public returns (uint256) {
    uint256[] memory planetOrb = new uint256[](4);
    planetOrb[0] = 80483655;
    planetOrb[1] = 199563560;
    planetOrb[2] = 19896517;
    planetOrb[3] = 36352283;

    uint256[] memory planetOrbNorm = new uint256[](4);
    maxPlanetOrb = max(planetOrb);
    for (uint i=0; i<planetOrb.length; i++) {
      planetOrbNorm[i] = (planetOrb[i] * 1000) / maxPlanetOrb;
    } 
    
    maxPlanetOrb = max(planetOrb);

    // console.log(sinTest.sin());
    // logArray('planetOrbNorm', planetOrbNorm);

    return maxPlanetOrb;
  }

  function logArray(string memory name, uint256[] memory array) public {
    console.log('------------------------------------------------------------------------------------');
    console.log(name);
    for (uint i=0; i<array.length; i++) {
      console.log(array[i]);
    } 
    console.log('------------------------------------------------------------------------------------');
  }

  // Visibility is `public` to enable it being called by other contracts for composition.
  function renderTokenById(uint256 id) public view returns (string memory) {
    string memory hostName = 'tau Cet';
    uint256 starRad = 577968;
    uint256 starTemp = 5310;
    uint256 starDist = 12;
    // uint256[4] memory planetR = [11532, 11532, 7518, 7581];
    // uint256[4] memory planetOrb = [80483655, 199563560, 19896517, 36352283];

    // Normalize planet radii
    // uint16[4] memory planetRNorm = planetR / max(planetR);

    // string[2] memory planetX = ['938', '500'];
    // string[2] memory planetY = ['500', '274'];
    // string[2] memory planetGradX1 = ['100', '50'];
    // string[2] memory planetGradX2 = ['0', '50'];
    // string[2] memory planetGradY1 = ['50', '0'];
    // string[2] memory planetGradY2 = ['50', '100'];
    // string memory starHex = 'fff2e7';
    // string[2] memory planetHex = ['945c1b', '7748b5'];
    

    // // Star radial gradient
    // string memory render = string(abi.encodePacked(
    //   '<defs>',
    //     '<radialGradient id="s" r="65%" spreadMethod="pad"><stop offset="0%" stop-color="#ffffff" stop-opacity="1" />',
    //       '<stop offset="60%" stop-color="#',
    //       starHex,
    //       '" stop-opacity="1" />',
    //       '<stop offset="80%" stop-color="#000000" stop-opacity="0" />',
    //     '</radialGradient>'
    // ));

    // // Planet linear gradients
    // for (uint i=0; i<planetHex.length; i++) {
    //   render = string(abi.encodePacked(
    //     render,
    //     '<linearGradient id="',
    //     planetHex[i],
    //     '" x1="100%" y1="50%" x2="0%" y2="50%" spreadMethod="pad">',
    //       '<stop offset="40.0%" stop-color="rgb(0, 0, 0)" stop-opacity="1" />',
    //       '<stop offset="100%" stop-color="#',
    //       planetHex[i],
    //       '" stop-opacity="1" />',
    //     '</linearGradient>'
    //   ));
    // }

    // // Star
    // render = string(abi.encodePacked(
    //   render,
    //   '</defs>',
    //   '<circle cx="500" cy="500" r="101.835107016" style="fill:url(#s);" />'
    // ));

    // // Planets
    //     for (uint i=0; i<planetHex.length; i++) {
    //   render = string(abi.encodePacked(
    //     render,
    //     '<circle cx="',
    //     planetX[i],
    //     '" cy="',
    //     planetY[i],
    //     '" r="',
    //     planetR[i],
    //     '" style="fill:url(#',
    //     planetHex[i],
    //     ');" />'
    //   ));
    // }

    string memory render = string(abi.encodePacked('<circle cx="500" cy="500" r="101.835107016" style="fill:#ffffff;" />'));

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
