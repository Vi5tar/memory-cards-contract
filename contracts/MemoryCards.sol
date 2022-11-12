// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "hardhat/console.sol";

contract MemoryCards is ERC721URIStorage {
    using Strings for uint256;
    using Strings for uint8;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    // map token id to map of game saves
    mapping(uint256 => mapping(string => string)) private _tokenGameSaves;

    // map token id to game names
    mapping(uint256 => string[]) private _tokenGameNames;

    constructor() ERC721("MemoryCards", "MC") {}

    /**
     * @dev Mints a new "Memory Card" token.
     */
    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    /**
     * @dev Save NES rom data to a "Memory Card" token.
     */
    function saveGame(uint256 tokenId, string memory gameName, string memory data)
        public
    {
        require(_exists(tokenId), "Memory card does not exist");
        require(ownerOf(tokenId) == msg.sender, "You do not own this memory card");

        console.log(gameName);
        console.log(data);

        _tokenGameSaves[tokenId][gameName] = data;
        _tokenGameNames[tokenId].push(gameName);
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }

    function loadGame(uint256 tokenId, string memory gameName)
        public
        view
        returns (string memory)
    {
        require(_exists(tokenId), "Memory card does not exist");
        require(ownerOf(tokenId) == msg.sender, "You do not own this memory card");

        return _tokenGameSaves[tokenId][gameName];
    }

    /**
     * @dev Generate SVG for the "Memory Card" token
     */
    function getTokenSvg(uint256 tokenId) public view returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="10%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Saved Games: ",
            "</text>",
            '<text x="50%" y="20%" class="base" dominant-baseline="middle" text-anchor="middle">',
            _serializeArrayOfStrings(_tokenGameNames[tokenId]),
            "</text>",
            "</svg>"
        );
        console.log("SVG: %s", string(svg));
        console.log("Encoded SVG: %s", Base64.encode(svg));

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    /**
     * @dev Gets the URI for the "Memory Card" token
     * @param tokenId The token ID to get the URI for
     */
    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Memory Card #',
            tokenId.toString(),
            '",',
            '"description": "A Memory Card for NES games.",',
            '"image": "',
            getTokenSvg(tokenId),
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    /**
     * @dev Serialize an array of strings
     */
    function _serializeArrayOfStrings(string[] memory array)
        internal
        pure
        returns (string memory)
    {
        string memory serialized = "";
        for (uint256 i = 0; i < array.length; i++) {
            serialized = string(abi.encodePacked(serialized, array[i]));
            if (i < array.length - 1) {
                serialized = string(abi.encodePacked(serialized, ","));
            }
        }
        return serialized;
    }
}
