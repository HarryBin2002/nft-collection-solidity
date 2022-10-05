// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleNFTCollection {
    address private _owner;

    struct NFT {
        uint256 tokenId;
        string tokenName;
    }

    NFT[] private listNFT;

    mapping(address => NFT[]) private ownerToListNFT;
    mapping(uint256 => address) private tokenIdToOwner;
    mapping(uint256 => bool) private tokenExist;
    mapping(address => uint256) private balances;

    mapping(uint256 => string) private idToName;



    constructor() {
        _owner = msg.sender;
    }

    function mintNFT(uint256 tokenId, string memory tokenName) public payable {
        _mint(msg.sender, tokenId, tokenName);
    }

    function _mint(address to, uint256 tokenId, string memory tokenName) internal {
        require(to != address(0), "address destination is not zero!!!");
        require(!tokenExist[tokenId], "TokenId exist!!!");

        listNFT.push(NFT(tokenId, tokenName));
        ownerToListNFT[msg.sender] = listNFT;
        tokenIdToOwner[tokenId] = msg.sender;
        idToName[tokenId] = tokenName;

        balances[msg.sender] += 1;
        tokenExist[tokenId] = true;
    }







    // GET FUNCTION
    function getOwner() public view returns (address) {
        return _owner;
    }

    function getBalances() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getOwnerToTokenId(address owner) public view returns (NFT[] memory) {
        return ownerToListNFT[owner];
    }

    function getTokenIdToOwner(uint256 tokenId) public view returns (address) {
        return tokenIdToOwner[tokenId];
    }

    function getNameFromId(uint256 tokenId) public view returns (string memory) {
        return idToName[tokenId];
    }
} 