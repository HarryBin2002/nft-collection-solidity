// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";


contract SimpleNFTCollection {
    address private _owner;

    struct NFT {
        uint256 tokenId;
        string tokenName;
    }

    NFT[] private listNFT;

    struct child {
        uint256 tokenId_child;
        string tokenName_child;
        uint256 tokenId_parent;
    }

    mapping(address => NFT[]) private ownerToListNFT;
    mapping(uint256 => address) private tokenIdToOwner;
    mapping(uint256 => bool) private tokenExist;
    mapping(address => uint256) private balances;

    mapping(uint256 => string) private idToName;


    mapping(uint256 => child[]) private tokenIdParentToChildren;
    mapping(uint256 => uint256) private tokenChildrenToParent;



    constructor() {
        _owner = msg.sender;
    }

    function mintNFT(uint256 tokenId, string memory tokenName) public payable {
        _mint(tokenId, tokenName);
    }

    function _mint(uint256 tokenId, string memory tokenName) internal {
        require(!tokenExist[tokenId], "TokenId exist!!!");

        listNFT.push(NFT(tokenId, tokenName));
        ownerToListNFT[msg.sender].push(NFT(tokenId, tokenName));
        tokenIdToOwner[tokenId] = msg.sender;

        balances[msg.sender] += 1;
        tokenExist[tokenId] = true;
        idToName[tokenId] = tokenName;
    }

    function addChildren(
        uint256 tokenId_parent, 
        uint256 tokenId_child, 
        string memory tokenName_child
    ) public {
        require(!tokenExist[tokenId_child], "TokenId exist!!!");

        tokenIdParentToChildren[tokenId_parent].push(child(tokenId_child, tokenName_child, tokenId_parent));
        tokenChildrenToParent[tokenId_child] = tokenId_parent;

        balances[msg.sender] += 1;
        tokenExist[tokenId_child] = true;
        idToName[tokenId_child] = tokenName_child;
    }

    // remove children
    function removeChildren(uint256 tokenId_child) public {
        require(tokenExist[tokenId_child], "NFT does not exist!!!");
        require(tokenExist[tokenChildrenToParent[tokenId_child]], "NFT parent does not exist!!!");
        require(tokenIdToOwner[tokenChildrenToParent[tokenId_child]] == msg.sender, "This is not owner of NFT");

        uint256 tokenId_parent = tokenChildrenToParent[tokenId_child];
        _remove(tokenId_child, tokenId_parent);
        balances[msg.sender] -= 1;
    }

    function _remove(uint256 tokenId_child, uint256 tokenId_parent) internal {
        uint256 index = _findIndex(tokenId_child, tokenId_parent);
        for(uint256 i = index; i < tokenIdParentToChildren[tokenId_parent].length - 1; i++) {
            tokenIdParentToChildren[tokenId_parent][i] = tokenIdParentToChildren[tokenId_parent][i+1];
        }
        tokenIdParentToChildren[tokenId_parent].pop();
        tokenExist[tokenId_child] = false;
    }

    function _findIndex(uint256 tokenId_child, uint256 tokenId_parent) internal view returns (uint256 index) {
        child[] memory lists = tokenIdParentToChildren[tokenId_parent];
        
        uint256 i = 0;
        for(; i < lists.length; i++) {
            if(lists[i].tokenId_child == tokenId_child) {
                return i;
            }
        }
    }

    // remove NFT
    function removeNFT(uint256 tokenId) public {
        require(tokenExist[tokenId], "This NFT does not exist!!!");
        require(tokenIdToOwner[tokenId] == msg.sender, "This owner does not have this NFT!!!");

        _removeNFT(tokenId);
        balances[msg.sender] -= 1;
    }

    function _removeNFT(uint256 tokenId) internal {
        child[] memory lists = tokenIdParentToChildren[tokenId];
        for(uint256 i = 0; i < lists.length; i++) {
            removeChildren(lists[i].tokenId_child);
        }

        uint256 index = _findIndexNFT(tokenId);
        for(uint256 i = index; i < listNFT.length - 1; i++) {
            listNFT[i] = listNFT[i+1];
        }
        listNFT.pop();

        for(uint256 i = index; i < ownerToListNFT[msg.sender].length - 1; i++) {
            ownerToListNFT[msg.sender][i] = ownerToListNFT[msg.sender][i+1];
        }
        ownerToListNFT[msg.sender].pop();

        tokenExist[tokenId] = false;
    }

    function _findIndexNFT(uint256 tokenId) internal view returns (uint256 index) {
        for(uint256 i = 0; i < listNFT.length; i++) {
            if(listNFT[i].tokenId == tokenId) {
                return i;
            }
        }
    }



    // Transfer
    function transferFrom(address from, address to, uint256 tokenId) public {
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(from != address(0), "From address is an empty address");
        require(to != address(0), "To address is an empty address");
        require(from != to, "From is not equal to To");
        require(tokenExist[tokenId], "This NFT does not exist!!!");
        require(from == msg.sender, "This is not owner");

        // set value to a variable is the same to the NFT needed to transfer 
        NFT memory exampleNFT = listNFT[_findIndexNFT(tokenId)];
        child[] memory exampleChildList = tokenIdParentToChildren[tokenId];

        // remove this NFT at From address
        removeNFT(tokenId);
        // add this NFT at To address
        _addNFT(to, exampleNFT, exampleChildList);
    }

    function _addNFT(address to, NFT memory exampleNFT, child[] memory exampleChildList) internal {

        // _mint this NFT to new owner
        listNFT.push(NFT(exampleNFT.tokenId, exampleNFT.tokenName));
        ownerToListNFT[to].push(NFT(exampleNFT.tokenId, exampleNFT.tokenName));
        tokenIdToOwner[exampleNFT.tokenId] = to;

        balances[to] += 1;
        tokenExist[exampleNFT.tokenId] = true;
        idToName[exampleNFT.tokenId] = exampleNFT.tokenName;

        // add children to new owner
        for(uint256 i = 0; i < exampleChildList.length; i++) {
            tokenIdParentToChildren[exampleNFT.tokenId].push(child(exampleChildList[i].tokenId_child, exampleChildList[i].tokenName_child, exampleNFT.tokenId));
            tokenChildrenToParent[exampleChildList[i].tokenId_child] = exampleNFT.tokenId;

            balances[to] += 1;
            tokenExist[exampleChildList[i].tokenId_child] = true;
            idToName[exampleChildList[i].tokenId_child] = exampleChildList[i].tokenName_child;
        }
    }













    // GET FUNCTION
    function getOwner() public view returns (address) {
        return _owner;
    }

    function getBalances() public view returns (uint256) {
        return balances[msg.sender];
    }

    function getListNFT(address owner) public view returns (string memory) {
        NFT[] memory lists = ownerToListNFT[owner];
        string memory result = "";
        for(uint256 i = 0; i < lists.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    lists[i].tokenName,
                    ", "
                )
            );
        }
        return result;
    }

    function getOwnerFromTokenId(uint256 tokenId) public view returns (address) {
        return tokenIdToOwner[tokenId];
    }

    function getListChildren(uint256 tokenId_parent) public view returns (string memory) {
        child[] memory lists = tokenIdParentToChildren[tokenId_parent];
        string memory result = "";
        for(uint256 i = 0; i < lists.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    lists[i].tokenName_child,
                    ", "        
                )
            );
        }
        return result;
    }

    function getOwnerOfChildren(uint256 tokenId_child) public view returns (address) {
        return tokenIdToOwner[tokenChildrenToParent[tokenId_child]];
    }

    function getNameFromId(uint256 tokenId) public view returns (string memory) {
        return idToName[tokenId];
    }
} 