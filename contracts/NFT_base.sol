// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract SimpleNFTCollection is ERC721 {
    
    address public owner;
    uint256 tokenId = 1;

    struct NFT {
        uint256 tokenId;
        string tokenName;
        address tokenOwner;
    }

    NFT[] public allNFTs;

    mapping(address => NFT[]) public ownerToNFT;
    mapping(string => bool) public tokenExist;

    constructor() ERC721("NFT_Collection_demo", "NCD") {
        owner = msg.sender;
    }

    // GET FUNCTION
    function getOwnerAddress() public view returns(address) {
        return owner;
    }

    function getAllNFts() public view returns (NFT[] memory) {
        return allNFTs;
    }

    function getMyNFT() public view returns(NFT[] memory) {
        return ownerToNFT[msg.sender];
    }

    function getMyNFTId(uint256 index) public view returns(uint256) {
        return ownerToNFT[msg.sender][index].tokenId;
    }

    function getMyNFTName(uint256 index) public view returns(string memory) {
        return ownerToNFT[msg.sender][index].tokenName;
    }

    function mintNFT(string memory _tokenName) public payable {
        require(!tokenExist[_tokenName], "This NFT exists!!!");

        _safeMint(msg.sender, tokenId);

        allNFTs.push(NFT(tokenId, _tokenName, msg.sender));
        ownerToNFT[msg.sender].push(NFT(tokenId, _tokenName, msg.sender));

        tokenExist[_tokenName] = true;
        tokenId++;
    }
}