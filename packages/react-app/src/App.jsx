import { Alert, Button, Col, Menu, Row } from "antd";
import "antd/dist/antd.css";
import {
  useBalance,
  useContractLoader,
  useContractReader,
  useGasPrice,
  useOnBlock,
  useUserProviderAndSigner,
} from "eth-hooks";
import { useExchangeEthPrice } from "eth-hooks/dapps/dex";
import React, { useCallback, useEffect, useState } from "react";
import { Link, Route, Switch, useLocation } from "react-router-dom";
import "./App.css";
import {
  Account,
  Address,
  Contract,
  Faucet,
  GasGauge,
  Header,
  Ramp,
  ThemeSwitch,
  NetworkDisplay,
  FaucetHint,
} from "./components";
import { NETWORKS, ALCHEMY_KEY } from "./constants";
import externalContracts from "./contracts/external_contracts";
// contracts
import deployedContracts from "./contracts/hardhat_contracts.json";
import { Transactor, Web3ModalSetup } from "./helpers";
import { YourExos, Exos } from "./views";
import { useStaticJsonRPC } from "./hooks";

var systemI = 0;

// Data for rendering example systems. See Structs.sol for a bit more on variable descriptions.
const systemData = [
  {
    "system_name": {
      "0": "TOI-178",
      "1": "GJ 9066",
      "2": "Kepler-79",
      "3": "Kepler-402",
      "4": "HD 108236",
      "5": "tau Cet",
      "6": "PDS 70",
      "7": "Kepler-342",
      "8": "GJ 3293",
      "9": "TOI-561",
      "10": "Kepler-215",
      "11": "DMPP-1",
      "12": "61 Vir",
      "13": "Kepler-49",
      "14": "EPIC 220674823",
      "15": "Kepler-122",
      "16": "Teegarden's Star",
      "17": "TOI-1749",
      "18": "Kepler-256",
      "19": "Kepler-55",
      "20": "Kepler-82",
      "21": "Kepler-169",
      "22": "YZ Cet",
      "23": "HAT-P-11",
      "24": "Kepler-84",
      "25": "HD 40307",
      "26": "Kepler-24",
      "27": "HD 181433",
      "28": "HD 215152",
      "29": "GJ 876",
      "30": "Kepler-292",
      "31": "Kepler-154",
      "32": "AU Mic",
      "33": "CoRoT-24",
      "34": "Kepler-37",
      "35": "K2-133",
      "36": "Kepler-102",
      "37": "WASP-47",
      "38": "Kepler-62",
      "39": "KELT-6",
      "40": "HD 34445",
      "41": "TRAPPIST-1",
      "42": "HD 10180",
      "43": "Kepler-11",
      "44": "Kepler-150",
      "45": "HIP 14810",
      "46": "K2-138",
      "47": "HD 141399",
      "48": "GJ 9827",
      "49": "K2-19",
      "50": "Kepler-758",
      "51": "CoRoT-20",
      "52": "HD 219134",
      "53": "CoRoT-7",
      "54": "GJ 581",
      "55": "L 98-59",
      "56": "HD 164922",
      "57": "Kepler-85",
      "58": "HD 20794",
      "59": "V1298 Tau",
      "60": "HD 191939",
      "61": "GJ 3323",
      "62": "Kepler-238",
      "63": "K2-285"
    },
    "system_dist": {
      "0": 206,
      "1": 15,
      "2": 3348,
      "3": 2051,
      "4": 212,
      "5": 12,
      "6": 371,
      "7": 2564,
      "8": 66,
      "9": 281,
      "10": 1594,
      "11": 205,
      "12": 28,
      "13": 1021,
      "14": 802,
      "15": 3370,
      "16": 13,
      "17": 327,
      "18": 3367,
      "19": 1898,
      "20": 2966,
      "21": 1333,
      "22": 12,
      "23": 124,
      "24": 3358,
      "25": 42,
      "26": 3794,
      "27": 88,
      "28": 71,
      "29": 15,
      "30": 3465,
      "31": 3002,
      "32": 32,
      "33": 1940,
      "34": 210,
      "35": 247,
      "36": 354,
      "37": 868,
      "38": 987,
      "39": 790,
      "40": 151,
      "41": 41,
      "42": 128,
      "43": 2120,
      "44": 2923,
      "45": 166,
      "46": 664,
      "47": 121,
      "48": 97,
      "49": 951,
      "50": 4928,
      "51": 2769,
      "52": 21,
      "53": 524,
      "54": 21,
      "55": 35,
      "56": 72,
      "57": 2509,
      "58": 20,
      "59": 355,
      "60": 176,
      "61": 18,
      "62": 5900,
      "63": 508
    },
    "star_radius": {
      "0": 59,
      "1": 22,
      "2": 101,
      "3": 99,
      "4": 75,
      "5": 71,
      "6": 99,
      "7": 112,
      "8": 41,
      "9": 73,
      "10": 84,
      "11": 99,
      "12": 80,
      "13": 51,
      "14": 79,
      "15": 96,
      "16": 20,
      "17": 52,
      "18": 101,
      "19": 54,
      "20": 76,
      "21": 67,
      "22": 20,
      "23": 61,
      "24": 110,
      "25": 64,
      "26": 87,
      "27": 69,
      "28": 65,
      "29": 33,
      "30": 71,
      "31": 82,
      "32": 66,
      "33": 73,
      "34": 69,
      "35": 46,
      "36": 65,
      "37": 91,
      "38": 58,
      "39": 129,
      "40": 106,
      "41": 20,
      "42": 89,
      "43": 86,
      "44": 78,
      "45": 87,
      "46": 73,
      "47": 107,
      "48": 56,
      "49": 71,
      "50": 109,
      "51": 84,
      "52": 68,
      "53": 71,
      "54": 35,
      "55": 33,
      "56": 79,
      "57": 98,
      "58": 77,
      "59": 104,
      "60": 78,
      "61": 20,
      "62": 110,
      "63": 69
    },
    "star_color": {
      "0": "ffd5b3",
      "1": "ffba81",
      "2": "fff8f1",
      "3": "fff7ef",
      "4": "fff0e3",
      "5": "ffe9d8",
      "6": "ffcda4",
      "7": "fff9f1",
      "8": "ffbf8a",
      "9": "ffecdc",
      "10": "fff1e5",
      "11": "fff9f2",
      "12": "ffeee0",
      "13": "ffcda4",
      "14": "ffefe1",
      "15": "fff6ee",
      "16": "ffad67",
      "17": "ffcda5",
      "18": "ffeedf",
      "19": "ffd6b5",
      "20": "ffeedf",
      "21": "ffe3cd",
      "22": "ffb677",
      "23": "ffdfc6",
      "24": "fff6ed",
      "25": "ffe3cc",
      "26": "fff2e7",
      "27": "ffe2cb",
      "28": "ffe2cb",
      "29": "ffba80",
      "30": "ffe9d7",
      "31": "fff0e3",
      "32": "ffc697",
      "33": "ffe3cc",
      "34": "ffebdb",
      "35": "ffc495",
      "36": "ffe2ca",
      "37": "ffeedf",
      "38": "ffe2cb",
      "39": "fff7ef",
      "40": "fff4e9",
      "41": "ffa14c",
      "42": "fff4ea",
      "43": "fff0e3",
      "44": "ffeee0",
      "45": "ffeedf",
      "46": "ffead9",
      "47": "ffefe1",
      "48": "ffd5b4",
      "49": "ffead8",
      "50": "fff9f3",
      "51": "fff4e9",
      "52": "ffddc3",
      "53": "ffe9d7",
      "54": "ffbd86",
      "55": "ffbe88",
      "56": "ffebda",
      "57": "ffedde",
      "58": "ffebdb",
      "59": "ffe3cc",
      "60": "ffead9",
      "61": "ffb678",
      "62": "fff1e5",
      "63": "ffe3cd"
    },
    "planet_radius": {
      "0": [9, 12, 16, 15, 15, 17],
      "1": [28, 40],
      "2": [19, 20, 31, 20],
      "3": [10, 12, 11, 11],
      "4": [12, 14, 16, 18, 14],
      "5": [13, 13, 10, 10],
      "6": [74, 61],
      "7": [15, 13, 16, 8],
      "8": [25, 24, 16, 12],
      "9": [11, 17, 16, 16, 15],
      "10": [12, 13, 15, 12],
      "11": [26, 18, 12, 13],
      "12": [14, 23, 25],
      "13": [17, 16, 12, 12],
      "14": [12, 14],
      "15": [15, 27, 14, 16, 12],
      "16": [9, 9],
      "17": [11, 14, 16],
      "18": [12, 14, 16, 15],
      "19": [15, 15, 12, 11, 12],
      "20": [22, 26, 13, 16, 24],
      "21": [9, 10, 10, 14, 16],
      "22": [8, 9, 9],
      "23": [23, 50],
      "24": [15, 15, 11, 16, 14],
      "25": [13, 16, 18, 14, 16],
      "26": [15, 17, 12, 17],
      "27": [15, 52, 52],
      "28": [10, 9, 11, 11],
      "29": [50, 52, 16, 21],
      "30": [10, 11, 15, 16, 15],
      "31": [15, 18, 21, 11, 11],
      "32": [22, 19],
      "33": [20, 25],
      "34": [4, 7, 13, 4],
      "35": [10, 12, 14, 12],
      "36": [5, 6, 10, 15, 8],
      "37": [47, 50, 19, 13],
      "38": [10, 6, 13, 12, 11],
      "39": [53, 49],
      "40": [52, 35, 28, 22, 31, 51],
      "41": [9, 9, 7, 8, 9, 9, 7],
      "42": [20, 19, 26, 26, 24, 38],
      "43": [13, 17, 18, 22, 16, 19],
      "44": [10, 20, 17, 18, 20],
      "45": [49, 51, 52],
      "46": [11, 15, 15, 19, 17, 18],
      "47": [52, 51, 51, 52],
      "48": [12, 10, 14],
      "49": [31, 22, 9],
      "50": [16, 12, 14, 11],
      "51": [38, 46],
      "52": [12, 11, 12, 10, 19, 48],
      "53": [12, 17],
      "54": [22, 15, 9],
      "55": [8, 11, 11, 12],
      "56": [50, 20, 13, 19],
      "57": [13, 14, 10, 10],
      "58": [11, 10, 14, 14],
      "59": [40, 27, 29, 36],
      "60": [19, 18, 18, 48, 48],
      "61": [10, 10],
      "62": [12, 15, 18, 27, 14],
      "63": [16, 20, 16, 13]
    },
    "planet_color_A": {
      "0": ["731919", "7a4218", "1037e3", "1037e3", "e012ad", "2e8718"],
      "1": ["3b1c63", "751d38"],
      "2": ["6521bf", "1cafba", "3b1c63", "6a12de"],
      "3": ["9c1c1c", "ba1818", "6521bf", "706914"],
      "4": ["7a4218", "202e6e", "965424", "196369", "196369"],
      "5": ["9c2a4c", "2040c9", "9c2a4c", "7a4218"],
      "6": ["196369", "731919"],
      "7": ["7a4218", "965424", "11805b", "2040c9"],
      "8": ["263b96", "751d38", "c72656", "9c1c1c"],
      "9": ["2e8718", "1037e3", "263b96", "c72656", "965424"],
      "10": ["202e6e", "eb0c0c", "9c2a4c", "706914"],
      "11": ["bdb020", "731919", "e61050", "c72656"],
      "12": ["11805b", "eb0c0c", "8c8424"],
      "13": ["c2621d", "263b96", "eb0c0c", "751d38"],
      "14": ["731919", "691954"],
      "15": ["2e8718", "1f878f", "e0cf14", "3fb322", "1cafba"],
      "16": ["e61050", "21bf8b"],
      "17": ["e61050", "bd2296", "e61050"],
      "18": ["6a12de", "1cafba", "3ad413", "11805b"],
      "19": ["582996", "1037e3", "6a12de", "2e8718", "1cafba"],
      "20": ["11805b", "6a12de", "c72656", "912676", "196369"],
      "21": ["bd2296", "e012ad", "965424", "2e8718", "3b1c63"],
      "22": ["ba1818", "11805b", "582996"],
      "23": ["21bf8b", "3b1c63"],
      "24": ["13d192", "2040c9", "c2621d", "196369", "3ad413"],
      "25": ["202e6e", "6a12de", "263b96", "202e6e", "7a4218"],
      "26": ["965424", "e0cf14", "691954", "3b1c63"],
      "27": ["6a12de", "706914", "263b96"],
      "28": ["1cafba", "21bf8b", "eb0c0c", "202e6e"],
      "29": ["731919", "731919", "7a4218", "6a12de"],
      "30": ["2e8718", "263b96", "9c2a4c", "6521bf", "912676"],
      "31": ["706914", "11805b", "228f6b", "9c1c1c", "1f878f"],
      "32": ["e0cf14", "e61050"],
      "33": ["bd2296", "8c8424"],
      "34": ["3ad413", "9c2a4c", "263b96", "731919"],
      "35": ["582996", "1037e3", "eb0c0c", "3ad413"],
      "36": ["11805b", "13d192", "965424", "3fb322", "582996"],
      "37": ["1037e3", "706914", "1037e3", "11805b"],
      "38": ["1f878f", "e66d17", "196369", "1f878f", "bd2296"],
      "39": ["691954", "ba1818"],
      "40": ["bd2296", "582996", "1cafba", "9c2a4c", "8c8424", "965424"],
      "41": [
        "912676",
        "eb0c0c",
        "c2621d",
        "6521bf",
        "202e6e",
        "c72656",
        "7a4218"
      ],
      "42": ["691954", "e012ad", "e012ad", "3fb322", "8c8424", "2040c9"],
      "43": ["2e8718", "202e6e", "582996", "9c2a4c", "c2621d", "c72656"],
      "44": ["965424", "e0cf14", "912676", "196369", "e61050"],
      "45": ["8c8424", "c2621d", "c72656"],
      "46": ["c2621d", "196369", "6a12de", "6521bf", "228f6b", "7a4218"],
      "47": ["eb0c0c", "7a4218", "21bf8b", "1f878f"],
      "48": ["e012ad", "1037e3", "e66d17"],
      "49": ["9c2a4c", "3ad413", "3fb322"],
      "50": ["e0cf14", "731919", "3fb322", "3ad413"],
      "51": ["6521bf", "1f878f"],
      "52": ["bdb020", "9c1c1c", "706914", "ba1818", "6a12de", "e012ad"],
      "53": ["e66d17", "3fb322"],
      "54": ["bdb020", "912676", "3ad413"],
      "55": ["196369", "6a12de", "6a12de", "582996"],
      "56": ["e66d17", "2e8718", "12d7e6", "912676"],
      "57": ["c2621d", "2040c9", "1f878f", "582996"],
      "58": ["eb0c0c", "9c2a4c", "3ad413", "731919"],
      "59": ["21bf8b", "13d192", "751d38", "6a12de"],
      "60": ["ba1818", "21bf8b", "e66d17", "196369", "e012ad"],
      "61": ["582996", "11805b"],
      "62": ["731919", "202e6e", "9c1c1c", "228f6b", "21bf8b"],
      "63": ["202e6e", "731919", "e012ad", "3b1c63"]
    },
    "planet_color_B": {
      "0": ["c72656", "2e8718", "706914", "e0cf14", "9c2a4c", "ba1818"],
      "1": ["691954", "228f6b"],
      "2": ["ba1818", "9c1c1c", "9c1c1c", "2040c9"],
      "3": ["21bf8b", "ba1818", "1f878f", "263b96"],
      "4": ["731919", "6a12de", "2e8718", "ba1818", "6521bf"],
      "5": ["ba1818", "706914", "bdb020", "3b1c63"],
      "6": ["965424", "731919"],
      "7": ["9c2a4c", "751d38", "e012ad", "196369"],
      "8": ["e61050", "228f6b", "6521bf", "202e6e"],
      "9": ["196369", "3ad413", "1037e3", "21bf8b", "7a4218"],
      "10": ["ba1818", "6a12de", "9c1c1c", "2040c9"],
      "11": ["e012ad", "e0cf14", "3b1c63", "8c8424"],
      "12": ["965424", "2e8718", "1f878f"],
      "13": ["bdb020", "389920", "7a4218", "e012ad"],
      "14": ["2e8718", "3b1c63"],
      "15": ["6a12de", "582996", "389920", "c72656", "9c2a4c"],
      "16": ["691954", "9c1c1c"],
      "17": ["e66d17", "c2621d", "eb0c0c"],
      "18": ["3fb322", "706914", "21bf8b", "6521bf"],
      "19": ["21bf8b", "6521bf", "13d192", "965424", "196369"],
      "20": ["21bf8b", "228f6b", "7a4218", "3ad413", "c72656"],
      "21": ["ba1818", "2e8718", "ba1818", "706914", "1f878f"],
      "22": ["bdb020", "8c8424", "263b96"],
      "23": ["bdb020", "751d38"],
      "24": ["196369", "9c2a4c", "3fb322", "e61050", "228f6b"],
      "25": ["731919", "706914", "965424", "12d7e6", "2040c9"],
      "26": ["6521bf", "e66d17", "202e6e", "c72656"],
      "27": ["196369", "bdb020", "8c8424"],
      "28": ["7a4218", "bd2296", "6a12de", "731919"],
      "29": ["691954", "13d192", "965424", "6a12de"],
      "30": ["9c2a4c", "582996", "1f878f", "12d7e6", "c72656"],
      "31": ["13d192", "1cafba", "228f6b", "6521bf", "3ad413"],
      "32": ["8c8424", "731919"],
      "33": ["582996", "3b1c63"],
      "34": ["bd2296", "1cafba", "9c2a4c", "912676"],
      "35": ["7a4218", "1f878f", "731919", "202e6e"],
      "36": ["582996", "e012ad", "965424", "13d192", "389920"],
      "37": ["2040c9", "9c1c1c", "7a4218", "8c8424"],
      "38": ["196369", "196369", "9c2a4c", "e012ad", "2e8718"],
      "39": ["263b96", "202e6e"],
      "40": ["9c2a4c", "3b1c63", "7a4218", "582996", "9c1c1c", "1f878f"],
      "41": [
        "e012ad",
        "e66d17",
        "3b1c63",
        "1037e3",
        "3fb322",
        "e66d17",
        "ba1818"
      ],
      "42": ["1cafba", "6a12de", "3fb322", "912676", "6521bf", "7a4218"],
      "43": ["691954", "6521bf", "3ad413", "582996", "e61050", "21bf8b"],
      "44": ["8c8424", "1cafba", "1f878f", "7a4218", "706914"],
      "45": ["eb0c0c", "21bf8b", "e012ad"],
      "46": ["12d7e6", "1f878f", "ba1818", "1cafba", "2e8718", "9c2a4c"],
      "47": ["731919", "582996", "912676", "21bf8b"],
      "48": ["3b1c63", "3b1c63", "eb0c0c"],
      "49": ["e0cf14", "3b1c63", "751d38"],
      "50": ["c2621d", "263b96", "912676", "706914"],
      "51": ["196369", "9c1c1c"],
      "52": ["bd2296", "2040c9", "c72656", "691954", "7a4218", "6a12de"],
      "53": ["c72656", "691954"],
      "54": ["196369", "13d192", "731919"],
      "55": ["6a12de", "965424", "bd2296", "1f878f"],
      "56": ["228f6b", "3b1c63", "8c8424", "ba1818"],
      "57": ["8c8424", "389920", "8c8424", "582996"],
      "58": ["8c8424", "ba1818", "9c1c1c", "389920"],
      "59": ["e66d17", "7a4218", "12d7e6", "3fb322"],
      "60": ["263b96", "bd2296", "e66d17", "2040c9", "13d192"],
      "61": ["12d7e6", "2040c9"],
      "62": ["bd2296", "ba1818", "21bf8b", "13d192", "13d192"],
      "63": ["6a12de", "389920", "9c1c1c", "e0cf14"]
    },
    "planet_color_C": {
      "0": ["bdb020", "691954", "1f878f", "965424", "1037e3", "912676"],
      "1": ["21bf8b", "1cafba"],
      "2": ["e61050", "3b1c63", "389920", "691954"],
      "3": ["965424", "582996", "2040c9", "11805b"],
      "4": ["13d192", "8c8424", "c2621d", "6a12de", "9c1c1c"],
      "5": ["e0cf14", "11805b", "ba1818", "731919"],
      "6": ["eb0c0c", "e012ad"],
      "7": ["691954", "389920", "2e8718", "202e6e"],
      "8": ["228f6b", "c72656", "1cafba", "8c8424"],
      "9": ["2040c9", "6521bf", "1037e3", "731919", "c2621d"],
      "10": ["196369", "3fb322", "1cafba", "21bf8b"],
      "11": ["6521bf", "6a12de", "e66d17", "202e6e"],
      "12": ["582996", "21bf8b", "6521bf"],
      "13": ["912676", "582996", "c2621d", "582996"],
      "14": ["6a12de", "1037e3"],
      "15": ["bdb020", "965424", "1f878f", "582996", "3b1c63"],
      "16": ["691954", "582996"],
      "17": ["751d38", "12d7e6", "202e6e"],
      "18": ["263b96", "7a4218", "e61050", "582996"],
      "19": ["9c2a4c", "3b1c63", "ba1818", "eb0c0c", "389920"],
      "20": ["706914", "1f878f", "bdb020", "3fb322", "6521bf"],
      "21": ["3fb322", "eb0c0c", "2e8718", "3b1c63", "6521bf"],
      "22": ["6521bf", "7a4218", "e0cf14"],
      "23": ["bd2296", "6521bf"],
      "24": ["751d38", "c2621d", "751d38", "11805b", "196369"],
      "25": ["e61050", "21bf8b", "eb0c0c", "13d192", "1037e3"],
      "26": ["263b96", "11805b", "c72656", "912676"],
      "27": ["bd2296", "751d38", "e0cf14"],
      "28": ["e012ad", "13d192", "691954", "9c2a4c"],
      "29": ["691954", "12d7e6", "706914", "bd2296"],
      "30": ["706914", "12d7e6", "bd2296", "e012ad", "196369"],
      "31": ["8c8424", "3fb322", "bdb020", "1037e3", "731919"],
      "32": ["e0cf14", "e012ad"],
      "33": ["7a4218", "12d7e6"],
      "34": ["7a4218", "706914", "7a4218", "2040c9"],
      "35": ["3ad413", "751d38", "7a4218", "3fb322"],
      "36": ["9c1c1c", "263b96", "751d38", "11805b", "7a4218"],
      "37": ["bd2296", "965424", "691954", "1037e3"],
      "38": ["12d7e6", "ba1818", "bdb020", "9c2a4c", "912676"],
      "39": ["6a12de", "7a4218"],
      "40": ["c72656", "bd2296", "eb0c0c", "9c2a4c", "706914", "12d7e6"],
      "41": [
        "6a12de",
        "263b96",
        "c2621d",
        "e66d17",
        "11805b",
        "7a4218",
        "263b96"
      ],
      "42": ["eb0c0c", "e61050", "12d7e6", "389920", "7a4218", "912676"],
      "43": ["912676", "2e8718", "1cafba", "1cafba", "bdb020", "202e6e"],
      "44": ["e66d17", "691954", "1cafba", "2040c9", "c72656"],
      "45": ["ba1818", "e012ad", "582996"],
      "46": ["e61050", "bd2296", "13d192", "c2621d", "bdb020", "731919"],
      "47": ["bd2296", "13d192", "eb0c0c", "9c2a4c"],
      "48": ["ba1818", "691954", "e66d17"],
      "49": ["e66d17", "196369", "202e6e"],
      "50": ["196369", "196369", "12d7e6", "691954"],
      "51": ["ba1818", "9c2a4c"],
      "52": ["21bf8b", "9c2a4c", "3b1c63", "c2621d", "1cafba", "228f6b"],
      "53": ["6a12de", "1cafba"],
      "54": ["ba1818", "e0cf14", "202e6e"],
      "55": ["1037e3", "9c1c1c", "c72656", "bd2296"],
      "56": ["706914", "21bf8b", "bdb020", "bd2296"],
      "57": ["ba1818", "751d38", "2e8718", "13d192"],
      "58": ["7a4218", "c2621d", "ba1818", "7a4218"],
      "59": ["9c2a4c", "12d7e6", "21bf8b", "9c2a4c"],
      "60": ["13d192", "9c1c1c", "228f6b", "6521bf", "9c2a4c"],
      "61": ["8c8424", "228f6b"],
      "62": ["731919", "263b96", "228f6b", "e0cf14", "2e8718"],
      "63": ["ba1818", "e012ad", "e0cf14", "751d38"]
    }
  }
  
];

const { ethers } = require("ethers");
/*
    Welcome to 🏗 scaffold-eth !

    Code:
    https://github.com/scaffold-eth/scaffold-eth

    Support:
    https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA
    or DM @austingriffith on twitter or telegram

    You should get your own Infura.io ID and put it in `constants.js`
    (this is your connection to the main Ethereum network for ENS etc.)


    🌏 EXTERNAL CONTRACTS:
    You can also bring in contract artifacts in `constants.js`
    (and then use the `useExternalContractLoader()` hook!)
*/

/// 📡 What chain are your contracts deployed to?
const targetNetwork = NETWORKS.localhost; // <------- select your target frontend network (localhost, rinkeby, xdai, mainnet)

// const ipfsAPI = require('ipfs-http-client');

const BufferList = require('bl/BufferList');


// 😬 Sorry for all the console logging
const DEBUG = false;
const NETWORKCHECK = false;

// 🛰 providers
if (DEBUG) console.log("📡 Connecting to Mainnet Ethereum");

// 🔭 block explorer URL
const blockExplorer = targetNetwork.blockExplorer;

const web3Modal = Web3ModalSetup();

// 🛰 providers
const providers = [
  "https://eth-mainnet.gateway.pokt.network/v1/lb/611156b4a585a20035148406",
  `https://eth-mainnet.alchemyapi.io/v2/${ALCHEMY_KEY}`,
  "https://rpc.scaffoldeth.io:48544",
];

function App(props) {
  const [injectedProvider, setInjectedProvider] = useState();
  const [address, setAddress] = useState();
  const location = useLocation();

  // load all your providers
  const localProvider = useStaticJsonRPC([
    process.env.REACT_APP_PROVIDER ? process.env.REACT_APP_PROVIDER : targetNetwork.rpcUrl,
  ]);
  const mainnetProvider = useStaticJsonRPC(providers);

  const logoutOfWeb3Modal = async () => {
    await web3Modal.clearCachedProvider();
    if (injectedProvider && injectedProvider.provider && typeof injectedProvider.provider.disconnect == "function") {
      await injectedProvider.provider.disconnect();
    }
    setTimeout(() => {
      window.location.reload();
    }, 1);
  };

  /* 💵 This hook will get the price of ETH from 🦄 Uniswap: */
  const price = useExchangeEthPrice(targetNetwork, mainnetProvider);

  /* 🔥 This hook will get the price of Gas from ⛽️ EtherGasStation */
  const gasPrice = useGasPrice(targetNetwork, "fast");
  // Use your injected provider from 🦊 Metamask or if you don't have it then instantly generate a 🔥 burner wallet.
  const userProviderAndSigner = useUserProviderAndSigner(injectedProvider, localProvider);
  const userSigner = userProviderAndSigner.signer;

  useEffect(() => {
    async function getAddress() {
      if (userSigner) {
        const newAddress = await userSigner.getAddress();
        setAddress(newAddress);
      }
    }
    getAddress();
  }, [userSigner]);

  // You can warn the user if you would like them to be on a specific network
  const localChainId = localProvider && localProvider._network && localProvider._network.chainId;
  const selectedChainId =
    userSigner && userSigner.provider && userSigner.provider._network && userSigner.provider._network.chainId;

  // For more hooks, check out 🔗eth-hooks at: https://www.npmjs.com/package/eth-hooks

  // The transactor wraps transactions and provides notificiations
  const tx = Transactor(userSigner, gasPrice);

  // 🏗 scaffold-eth is full of handy hooks like this one to get your balance:
  const yourLocalBalance = useBalance(localProvider, address);

  // Just plug in different 🛰 providers to get your balance on different chains:
  const yourMainnetBalance = useBalance(mainnetProvider, address);

  // const contractConfig = useContractConfig();

  const contractConfig = { deployedContracts: deployedContracts || {}, externalContracts: externalContracts || {} };

  // Load in your local 📝 contract and read a value from it:
  const readContracts = useContractLoader(localProvider, contractConfig);

  // If you want to make 🔐 write transactions to your contracts, use the userSigner:
  const writeContracts = useContractLoader(userSigner, contractConfig, localChainId);

  // EXTERNAL CONTRACT EXAMPLE:
  //
  // If you want to bring in the mainnet DAI contract it would look like:
  const mainnetContracts = useContractLoader(mainnetProvider, contractConfig);

  // If you want to call a function on a new block
  useOnBlock(mainnetProvider, () => {
    console.log(`⛓ A new mainnet block is here: ${mainnetProvider._lastBlockNumber}`);
  });

  const priceToMint = useContractReader(readContracts, "YourCollectible", "price");
  if (DEBUG) console.log("🤗 priceToMint:", priceToMint);

  const totalSupply = useContractReader(readContracts, "YourCollectible", "totalSupply");
  if (DEBUG) console.log("🤗 totalSupply:", totalSupply);
  const loogiesLeft = 64 - totalSupply;

  // keep track of a variable from the contract in the local React state:
  const balance = useContractReader(readContracts, "YourCollectible", "balanceOf", [address]);
  if (DEBUG) console.log("🤗 address: ", address, " balance:", balance);

  //
  // 🧠 This effect will update yourCollectibles by polling when your balance changes
  //
  const yourBalance = balance && balance.toNumber && balance.toNumber();
  const [yourCollectibles, setYourCollectibles] = useState();
  const [transferToAddresses, setTransferToAddresses] = useState({});

  useEffect(() => {
    const updateYourCollectibles = async () => {
      const collectibleUpdate = [];
      for (let tokenIndex = 0; tokenIndex < balance; tokenIndex++) {
        try {
          if (DEBUG) console.log("Getting token index", tokenIndex);
          const tokenId = await readContracts.YourCollectible.tokenOfOwnerByIndex(address, tokenIndex);
          if (DEBUG) console.log("Getting Loogie tokenId: ", tokenId);
          const tokenURI = await readContracts.YourCollectible.tokenURI(tokenId);
          if (DEBUG) console.log("tokenURI: ", tokenURI);
          const jsonManifestString = atob(tokenURI.substring(29));

          try {
            const jsonManifest = JSON.parse(jsonManifestString);
            collectibleUpdate.push({ id: tokenId, uri: tokenURI, owner: address, ...jsonManifest });
          } catch (e) {
            console.log(e);
          }
        } catch (e) {
          console.log(e);
        }
      }
      setYourCollectibles(collectibleUpdate.reverse());
    };
    updateYourCollectibles();
  }, [address, yourBalance]);

  //
  // 🧫 DEBUG 👨🏻‍🔬
  //
  useEffect(() => {
    if (
      DEBUG &&
      mainnetProvider &&
      address &&
      selectedChainId &&
      yourLocalBalance &&
      yourMainnetBalance &&
      readContracts &&
      writeContracts &&
      mainnetContracts
    ) {
      console.log("_____________________________________ 🏗 scaffold-eth _____________________________________");
      console.log("🌎 mainnetProvider", mainnetProvider);
      console.log("🏠 localChainId", localChainId);
      console.log("👩‍💼 selected address:", address);
      console.log("🕵🏻‍♂️ selectedChainId:", selectedChainId);
      console.log("💵 yourLocalBalance", yourLocalBalance ? ethers.utils.formatEther(yourLocalBalance) : "...");
      console.log("💵 yourMainnetBalance", yourMainnetBalance ? ethers.utils.formatEther(yourMainnetBalance) : "...");
      console.log("📝 readContracts", readContracts);
      console.log("🌍 DAI contract on mainnet:", mainnetContracts);
      console.log("🔐 writeContracts", writeContracts);
    }
  }, [
    mainnetProvider,
    address,
    selectedChainId,
    yourLocalBalance,
    yourMainnetBalance,
    readContracts,
    writeContracts,
    mainnetContracts,
  ]);

  const loadWeb3Modal = useCallback(async () => {
    const provider = await web3Modal.connect();
    setInjectedProvider(new ethers.providers.Web3Provider(provider));

    provider.on("chainChanged", chainId => {
      console.log(`chain changed to ${chainId}! updating providers`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    provider.on("accountsChanged", () => {
      console.log(`account changed!`);
      setInjectedProvider(new ethers.providers.Web3Provider(provider));
    });

    // Subscribe to session disconnection
    provider.on("disconnect", (code, reason) => {
      console.log(code, reason);
      logoutOfWeb3Modal();
    });
  }, [setInjectedProvider]);

  useEffect(() => {
    if (web3Modal.cachedProvider) {
      loadWeb3Modal();
    }
  }, [loadWeb3Modal]);

  const faucetAvailable = localProvider && localProvider.connection && targetNetwork.name.indexOf("local") !== -1;

  return (
    <div className="App">
      {/* ✏️ Edit the header and change the title to your project name */}
      <Header />
      <NetworkDisplay
        NETWORKCHECK={NETWORKCHECK}
        localChainId={localChainId}
        selectedChainId={selectedChainId}
        targetNetwork={targetNetwork}
      />
      <Menu style={{ textAlign: "center" }} selectedKeys={[location.pathname]} mode="horizontal">
        <Menu.Item key="/">
          <Link to="/">Home</Link>
        </Menu.Item>
        <Menu.Item key="/yourExos">
          <Link to="/yourExos">Your Exos</Link>
        </Menu.Item>
        <Menu.Item key="/howto">
          <Link to="/howto">How To Use Optimistic Network</Link>
        </Menu.Item>
        <Menu.Item key="/debug">
          <Link to="/debug">Debug Contracts</Link>
        </Menu.Item>
      </Menu>

      <div style={{ maxWidth: 820, margin: "auto", marginTop: 32, paddingBottom: 32 }}>
        <div style={{ fontSize: 16 }}>
          <p>
            Mint will load a system's data from the systemData JSON object in app.jsx and render an NFT.
          </p>
        </div>

        <div style={{height: "10px"}}></div>
        
        <Button
          type="primary"
          onClick={async () => {
            const priceRightNow = await readContracts.YourCollectible.price();
            // const systemI = await readContracts.YourCollectible.thisId();
            try {
              const txLoad = await tx(writeContracts.SystemData.createSystem(
                systemData[0].system_name[systemI],
                systemData[0].system_dist[systemI],
                systemData[0].star_radius[systemI],
                systemData[0].star_color[systemI],
                systemData[0].planet_radius[systemI],
                systemData[0].planet_color_A[systemI],
                systemData[0].planet_color_B[systemI],
                systemData[0].planet_color_C[systemI]
              ));
              await txLoad.wait();
              const txCur = await tx(writeContracts.YourCollectible.mintItem({ value: priceRightNow, gasLimit: 300000 }));
              await txCur.wait();
              systemI++;
            } catch (e) {
              console.log("mint failed", e);
            }
          }}
        >
          MINT for Ξ{priceToMint && (+ethers.utils.formatEther(priceToMint)).toFixed(4)}
        </Button>

        <p style={{ fontWeight: "bold" }}>
          { loogiesLeft } left
        </p>
      </div>

      <Switch>
        <Route exact path="/">
          <Exos
            readContracts={readContracts}
            mainnetProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            totalSupply={totalSupply}
            DEBUG={DEBUG}
          />
        </Route>
        <Route exact path="/yourExos">
          <YourExos
            readContracts={readContracts}
            writeContracts={writeContracts}
            priceToMint={priceToMint}
            yourCollectibles={yourCollectibles}
            tx={tx}
            mainnetProvider={mainnetProvider}
            blockExplorer={blockExplorer}
            transferToAddresses={transferToAddresses}
            setTransferToAddresses={setTransferToAddresses}
            address={address}
          />
        </Route>
        <Route exact path="/howto">
          <div style={{ fontSize: 18, width: 820, margin: "auto" }}>
            <h2 style={{ fontSize: "2em", fontWeight: "bold" }}>How to add Optimistic Ethereum network on MetaMask</h2>
            <div style={{ textAlign: "left", marginLeft: 50, marginBottom: 50 }}>
              <ul>
                <li>
                  Go to <a target="_blank" href="https://chainid.link/?network=optimism">https://chainid.link/?network=optimism</a>
                </li>
                <li>
                  Click on <strong>connect</strong> to add the <strong>Optimistic Ethereum</strong> network in <strong>MetaMask</strong>.
                </li>
              </ul>
            </div>
            <h2 style={{ fontSize: "2em", fontWeight: "bold" }}>How to add funds to your wallet on Optimistic Ethereum network</h2>
            <div style={{ textAlign: "left", marginLeft: 50, marginBottom: 100 }}>
              <ul>
                <li><a href="https://portr.xyz/" target="_blank">The Teleporter</a>: the cheaper option, but with a 0.05 ether limit per transfer.</li>
                <li><a href="https://gateway.optimism.io/" target="_blank">The Optimism Gateway</a>: larger transfers and cost more.</li>
                <li><a href="https://app.hop.exchange/send?token=ETH&sourceNetwork=ethereum&destNetwork=optimism" target="_blank">Hop.Exchange</a>: where you can send from/to Ethereum mainnet and other L2 networks.</li>
              </ul>
            </div>
          </div>
        </Route>
        <Route exact path="/debug">
          <div style={{ padding: 32 }}>
            <Address value={readContracts && readContracts.YourCollectible && readContracts.YourCollectible.address} />
          </div>
          <Contract
            name="SystemData"
            price={price}
            signer={userSigner}
            provider={localProvider}
            address={address}
            blockExplorer={blockExplorer}
            contractConfig={contractConfig}
          />
          <Contract
            name="YourCollectible"
            price={price}
            signer={userSigner}
            provider={localProvider}
            address={address}
            blockExplorer={blockExplorer}
            contractConfig={contractConfig}
          />
        </Route>
      </Switch>

      <div style={{ maxWidth: 820, margin: "auto", marginTop: 32 }}>
        🛠 built with <a href="https://github.com/scaffold-eth/scaffold-eth" target="_blank">🏗 scaffold-eth</a>
        🍴 <a href="https://github.com/scaffold-eth/scaffold-eth" target="_blank">Fork this repo</a> and build a cool SVG NFT!
      </div>

      <ThemeSwitch />

      {/* 👨‍💼 Your account is in the top right with a wallet at connect options */}
      <div style={{ position: "fixed", textAlign: "right", right: 0, top: 0, padding: 10 }}>
        <Account
          address={address}
          localProvider={localProvider}
          userSigner={userSigner}
          mainnetProvider={mainnetProvider}
          price={price}
          web3Modal={web3Modal}
          loadWeb3Modal={loadWeb3Modal}
          logoutOfWeb3Modal={logoutOfWeb3Modal}
          blockExplorer={blockExplorer}
        />
        <FaucetHint localProvider={localProvider} targetNetwork={targetNetwork} address={address} />
      </div>

      {/* 🗺 Extra UI like gas price, eth price, faucet, and support: */}
      <div style={{ position: "fixed", textAlign: "left", left: 0, bottom: 20, padding: 10 }}>
        <Row align="middle" gutter={[4, 4]}>
          <Col span={8}>
            <Ramp price={price} address={address} networks={NETWORKS} />
          </Col>

          <Col span={8} style={{ textAlign: "center", opacity: 0.8 }}>
            <GasGauge gasPrice={gasPrice} />
          </Col>
          <Col span={8} style={{ textAlign: "center", opacity: 1 }}>
            <Button
              onClick={() => {
                window.open("https://t.me/joinchat/KByvmRe5wkR-8F_zz6AjpA");
              }}
              size="large"
              shape="round"
            >
              <span style={{ marginRight: 8 }} role="img" aria-label="support">
                💬
              </span>
              Support
            </Button>
          </Col>
        </Row>

        <Row align="middle" gutter={[4, 4]}>
          <Col span={24}>
            {
              /*  if the local provider has a signer, let's show the faucet:  */
              faucetAvailable ? (
                <Faucet localProvider={localProvider} price={price} ensProvider={mainnetProvider} />
              ) : (
                ""
              )
            }
          </Col>
        </Row>
      </div>
    </div>
  );
}

export default App;
