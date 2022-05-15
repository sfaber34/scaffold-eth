# 🏗 scaffold-eth - Exos

Renders animated SVG NFTs of star systems on Optimism. They look something like this but with 100% more spin.

![Example Exo NFT](https://github.com/sfaber34/scaffold-eth/blob/exos/ExampleExo.png?raw=true)

This project is a fork of Optimistic Loogies
https://optimistic.loogies.io/
https://github.com/scaffold-eth/scaffold-eth/tree/optimistic-loogies-master

It's a hack job - definintly not coded in a very efficient way and the method of pulling system attributes at mint could easily be gamed.

BUT it draws some spinny solar system NFTs. Hopefully it's a jumping off point for something cooler.


# 🏄‍♂️ Quick Start

## Prerequisites

[Node](https://nodejs.org/en/download/) plus [Yarn](https://classic.yarnpkg.com/en/docs/install/) and [Git](https://git-scm.com/downloads)

## Getting Started

### Installation

### Manual setup

> clone/fork 🏗 scaffold-eth optimistic-loogies-master branch:

```
git clone -b exos https://github.com/sfaber34/scaffold-eth.git exos
```

> install and start your 👷‍ Hardhat chain:

```bash
cd exos
yarn install
yarn chain
```

> in a second terminal window, start your 📱 frontend:

```bash
cd exos
yarn start
```

> in a third terminal window, 🛰 deploy your contract:

```bash
cd exos
yarn deploy
```

🌍 You need an RPC key for production deployments/Apps, create an [Alchemy](https://www.alchemy.com/) account and replace the value of `ALCHEMY_KEY = xxx` in `packages/react-app/src/constants.js`

🔏 Edit your smart contracts `packages/hardhat/contracts`.

📝 Edit your frontend `App.jsx` in `packages/react-app/src`

💼 Edit your deployment scripts in `packages/hardhat/deploy`

📱 Open http://localhost:3000 to see the app


## Introduction

This branch renders animated solar system svg NFTs based on provided details about the system's star and planets.


Structs.sol contains struct definitions used to hold system attributes:

```
  struct Planet {
    uint8 radius; // Planet radius (pixels)
    uint16 orbDist; // Planet orbit distance; radial distance from star centroid to planet centroid (pixels)
    string colorA; // Base planet color (hex)
    string colorB; // Secondary planet color (hex)
    string colorC; // Tertiary planet color (hex)
  }

  struct System {
    string name; // Just used for nft attributes, mainly to draw text in bottom svg corners
    uint16 distToSol; // Similiar to name. Not used in layout logic or anything
    uint8 radius; // Star radius (pixels)
    string color; // Star color (hex)
    address owner;
    uint256[] planets; // stores ids of planets in each system
  }
```
System.name and System.distToSol are just used to render text in the bottom corners of NFTs. System.radius, System.color, Planet.radius, Planet.orbDist, Planet.colorA, Planet.colorB, and Planet.colorC are used for layout logic. Please note that Planet.orbDist is calculated and does not need to be provided like other Planet attributes.


SystemData.sol has functions for filling/returning System/Planet structs. It also calculates planet orbit distance from star centroid to planet centroid (pixels) based on the order that planets are passed to createSystem(). It makes the orbit gap between planets (roughly) the same. Data used to fill structs is passed from the App.jsx "Mint" button's onClick function.


The logic for building out star system SVGs for render lives in the ReturnSvg.sol library.
```
function returnSvg()
```
Gets System and Planets structs from SystemData.sol and does a bunch of string(abi.encodePacked()) to build out SVG tags for render.

Initial planet xy positions are calculated by trig identities in
```
function calcPlanetXY(uint256 rDist_, uint256 rads)
```

The remaining attributes needed for layout are pulled from System/Planet structs.


Much of the code in YourCollectible.sol is the same as Optimistic Loogies (some things in there definitely need edits to work with this fork if you want to take it live).

## Known Issues

- 

# 📚 Documentation

Documentation, tutorials, challenges, and many more resources, visit: [docs.scaffoldeth.io](https://docs.scaffoldeth.io)

# 🔭 Learning Solidity

📕 Read the docs: https://docs.soliditylang.org

📚 Go through each topic from [solidity by example](https://solidity-by-example.org) editing `YourContract.sol` in **🏗 scaffold-eth**

- [Primitive Data Types](https://solidity-by-example.org/primitives/)
- [Mappings](https://solidity-by-example.org/mapping/)
- [Structs](https://solidity-by-example.org/structs/)
- [Modifiers](https://solidity-by-example.org/function-modifier/)
- [Events](https://solidity-by-example.org/events/)
- [Inheritance](https://solidity-by-example.org/inheritance/)
- [Payable](https://solidity-by-example.org/payable/)
- [Fallback](https://solidity-by-example.org/fallback/)

📧 Learn the [Solidity globals and units](https://solidity.readthedocs.io/en/v0.6.6/units-and-global-variables.html)

# 🛠 Buidl

Check out all the [active branches](https://github.com/austintgriffith/scaffold-eth/branches/active), [open issues](https://github.com/austintgriffith/scaffold-eth/issues), and join/fund the 🏰 [BuidlGuidl](https://BuidlGuidl.com)!


 - 🚤  [Follow the full Ethereum Speed Run](https://medium.com/@austin_48503/%EF%B8%8Fethereum-dev-speed-run-bd72bcba6a4c)


 - 🎟  [Create your first NFT](https://github.com/austintgriffith/scaffold-eth/tree/simple-nft-example)
 - 🥩  [Build a staking smart contract](https://github.com/austintgriffith/scaffold-eth/tree/challenge-1-decentralized-staking)
 - 🏵  [Deploy a token and vendor](https://github.com/austintgriffith/scaffold-eth/tree/challenge-2-token-vendor)
 - 🎫  [Extend the NFT example to make a "buyer mints" marketplace](https://github.com/austintgriffith/scaffold-eth/tree/buyer-mints-nft)
 - 🎲  [Learn about commit/reveal](https://github.com/austintgriffith/scaffold-eth/tree/commit-reveal-with-frontend)
 - ✍️  [Learn how ecrecover works](https://github.com/austintgriffith/scaffold-eth/tree/signature-recover)
 - 👩‍👩‍👧‍👧  [Build a multi-sig that uses off-chain signatures](https://github.com/austintgriffith/scaffold-eth/tree/meta-multi-sig)
 - ⏳  [Extend the multi-sig to stream ETH](https://github.com/austintgriffith/scaffold-eth/tree/streaming-meta-multi-sig)
 - ⚖️  [Learn how a simple DEX works](https://medium.com/@austin_48503/%EF%B8%8F-minimum-viable-exchange-d84f30bd0c90)
 - 🦍  [Ape into learning!](https://github.com/austintgriffith/scaffold-eth/tree/aave-ape)

# 💬 Support Chat

Join the telegram [support chat 💬](https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA) to ask questions and find others building with 🏗 scaffold-eth!

---

🙏 Please check out our [Gitcoin grant](https://gitcoin.co/grants/2851/scaffold-eth) too!
