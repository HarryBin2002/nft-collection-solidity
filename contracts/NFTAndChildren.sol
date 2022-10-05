// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract NFTAndChildren {
    address private _owner;

    // Create struct NFT
    struct NFT {
        uint256 tokenId;
        string tokenName;
    }

    // ListNFT is used to store all NFT is minted by all owner
    NFT[] private listNFTs;

    // Create struct CHILD
    struct CHILD {
        uint256 tokenId_child;
        string tokenName_child;
        uint256 tokenId_parent;
    }


    // manage list NFT of each owner by its address
    mapping (address => NFT[]) private ownerToListNFT; 
    // store infor owner of each NFT
    mapping(uint256 => address) private tokenIdToOwner; 
    
    // checking a NFT does exist or not
    mapping(uint256 => bool) private tokenExist;
    // store and checking the amount of NFT and its children that owners have
    mapping(address => uint256) private balances;


    // linking Token ID with Name of a NFT.
    mapping(uint256 => string) private idToName;


    // manage list CHILD of each NFT parent by its ID
    mapping(uint256 => CHILD[]) private tokenIdParentToListChildren;
    // store infor NFT parent of each child by ID
    mapping(uint256 => uint256) private tokenIdChildToParent;

    constructor() {
        _owner = msg.sender;
    }

    // MINT NEW NFT
    function mintNFT(uint256 tokenId, string memory tokenName) public payable {
        _mint(tokenId, tokenName);
    }

    function _mint(uint256 tokenId, string memory tokenName) internal {
        // checking this token ID does exist or not
        require(!tokenExist[tokenId], "TokenId exist!!!");

        // push new NFT to ListNFTs
        listNFTs.push(NFT(tokenId, tokenName));
        // create and push to the own list NFT of each owner address
        ownerToListNFT[msg.sender].push(NFT(tokenId, tokenName));
        // assign owner of this NFT by owner address
        tokenIdToOwner[tokenId] = msg.sender;

        // Update data: balances, status token Exist, link ID and Name
        balances[msg.sender] += 1;
        tokenExist[tokenId] = true;
        idToName[tokenId] = tokenName;
    }

    // ADD NEW NFT CHILDREN
    function addNFTChildren(
        uint256 tokenId_parent,
        uint256 tokenId_child,
        string memory tokenName_child
    ) public {
        // checking the ID of NFT parent and child do exist or not
        require(!tokenExist[tokenId_child], "TokenId NFT children exist!!!");
        require(tokenExist[tokenId_parent], "TokenId NFT parent does not exist!!!");

        // create and push to the NFT parent a new NFT child
        tokenIdParentToListChildren[tokenId_parent].push(
            CHILD(tokenId_child, tokenName_child, tokenId_parent)
        );
        // ssign owner of this NFT child by NFT parent ID
        tokenIdChildToParent[tokenId_child] = tokenId_parent;

        // Update data: balances, status token Exist, link ID and Name
        balances[msg.sender] += 1;
        tokenExist[tokenId_child] = true;
        idToName[tokenId_child] = tokenName_child;
    }

    // REMOVE NFT CHILDREN
    function removeNFTChildren(uint256 tokenId_child) public {
        // checking the ID of NFT parent and child do exist or not
        require(tokenExist[tokenId_child], "NFT child does not exist!!!");
        require(tokenExist[tokenIdChildToParent[tokenId_child]], "NFT parent does not exist!!!");
        // checking this NFT child is belong to the NFT parent which is belong to this address call this function
        require(tokenIdToOwner[tokenIdChildToParent[tokenId_child]] == msg.sender, "This is not owner of NFT");

        uint256 tokenId_parent = tokenIdChildToParent[tokenId_child]; // get tokenId parent to use
        _removeNFTChildren(tokenId_child, tokenId_parent);
    }

    /**
    get the index of NFT child
    loop the array which store list NFT children to remove 
    */
    function _removeNFTChildren(uint256 tokenId_child, uint256 tokenId_parent) internal {
        uint256 index = _findIndexNFTChild(tokenId_child, tokenId_parent);
        for(uint256 i = index; i < tokenIdParentToListChildren[tokenId_parent].length - 1; i++) {
            tokenIdParentToListChildren[tokenId_parent][i] = tokenIdParentToListChildren[tokenId_parent][i+1];
        }
        tokenIdParentToListChildren[tokenId_parent].pop(); // remove one index 

        // Update 
        tokenExist[tokenId_child] = false;
        balances[msg.sender] -= 1;
    }

    // create a example list child to find the index of the NFT child
    function _findIndexNFTChild(uint256 tokenId_child, uint256 tokenId_parent) internal view returns (uint256 index) {
        CHILD[] memory listChild_exam = tokenIdParentToListChildren[tokenId_parent];
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            if(listChild_exam[i].tokenId_child == tokenId_child) {
                return i;
            }
        }
    }

    // REMOVE NFT PARENT
    function removeNFTParent(uint256 tokenId_parent) public {
        // checking the ID of NFT parent does exist or not
        require(tokenExist[tokenId_parent], "This NFT does not exist!!!");
        // Checking that NFT is belong to this owner address
        require(tokenIdToOwner[tokenId_parent] == msg.sender, "This owner does not have this NFT!!!");

        _removeNFTParent(tokenId_parent);
    }

    /**
    get the index of NFT parent
    loop the array which store list NFT parent to remove 
    remove also all the NFT children which are belong to NFt parent
    */
    function _removeNFTParent(uint256 tokenId_parent) internal {
        // remove all NFT children are belong to this NFT parent
        CHILD[] memory listChild_exam = tokenIdParentToListChildren[tokenId_parent];
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            removeNFTChildren(listChild_exam[i].tokenId_child);
        }

        uint256 index = _findIndexNFTParent(tokenId_parent);
        // remove NFT parent in ListNFTs (store all minted NFT)
        for(uint256 i = index; i < listNFTs.length - 1; i++) {
            listNFTs[i] = listNFTs[i+1];
        }

        // remove NFT parent in array NFT belongs to owner address
        for(uint256 i = index; i < ownerToListNFT[msg.sender].length - 1; i++) {
            ownerToListNFT[msg.sender][i] = ownerToListNFT[msg.sender][i+1]; 
        }
        ownerToListNFT[msg.sender].pop();

        // Update
        tokenExist[tokenId_parent] = false;
        balances[msg.sender] -= 1;
        tokenIdToOwner[tokenId_parent] = address(0);
    }

    // create a example list child to find the index of the NFT parent
    function _findIndexNFTParent(uint256 tokenId_parent) internal view returns (uint256 index) {
        NFT[] memory listNFT_exam = ownerToListNFT[msg.sender];
        for(uint256 i = 0; i < listNFT_exam.length; i++) {
            if(listNFT_exam[i].tokenId == tokenId_parent) {
                return i;
            }
        }
    }


    // TRANSFER NFT parent
    function transferFrom(address from, address to, uint256 tokenId_parent) public {
        _transfer(from, to, tokenId_parent);
    }

    function _transfer(address from, address to, uint256 tokenId_parent) internal {
        require(from != address(0), "From address is an empty address");
        require(to != address(0), "To address is an empty address");
        require(from != to, "From is not equal to To");
        require(tokenExist[tokenId_parent], "This NFT does not exist!!!");
        require(from == msg.sender, "This is not owner");

        // Get NFT and NFT children
        NFT memory NFT_exam = ownerToListNFT[msg.sender][_findIndexNFTParent(tokenId_parent)];
        CHILD[] memory listChild_exam = tokenIdParentToListChildren[tokenId_parent];

        // remove NFT
        removeNFTParent(tokenId_parent);
        
        // add NFT to new owner address
        _addNFTParent(to, NFT_exam, listChild_exam);
    }

    function _addNFTParent(address to, NFT memory NFT_exam, CHILD[] memory listChild_exam) internal {
        // Add that NFT parent to listNFTs again
        listNFTs.push(NFT_exam);

        // mint that NFT parent to new owner address
        ownerToListNFT[to].push(NFT_exam);
        tokenIdToOwner[NFT_exam.tokenId] = to;
        // Update
        balances[to] += 1;
        tokenExist[NFT_exam.tokenId] = true;
        idToName[NFT_exam.tokenId] = NFT_exam.tokenName;

        /**
        add all NFT children belong to NFT parent to new owner address
        Using for loop
        each loop time is adding a NFT child 
        */ 
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            tokenIdParentToListChildren[NFT_exam.tokenId].push(CHILD(listChild_exam[i].tokenId_child, listChild_exam[i].tokenName_child, NFT_exam.tokenId));
            tokenIdChildToParent[listChild_exam[i].tokenId_child] = NFT_exam.tokenId;

            balances[to] += 1;
            tokenExist[listChild_exam[i].tokenId_child] = true;
            idToName[listChild_exam[i].tokenId_child] = listChild_exam[i].tokenName_child;
        }
    }

    // GET FUNCTION

    // Common Get function: everyone can call
    function getOwnerAddress() public view returns (address Owner_SMC) {
        return _owner;
    } 

    function getBalances() public view returns (uint256 AmountNFT) {
        return balances[msg.sender];
    }

    function getOwnerOfNFTParent(uint256 tokenId_parent) public view returns (address Owner_NFT) {
        return tokenIdToOwner[tokenId_parent];
    }

    function getOwnerOfNFTChild(uint256 tokenId_child)  public view returns (address Owner, string memory NFTParentName, uint256 NFTParentId) {
        // get owner address
        address result_ownerAddress = tokenIdToOwner[tokenIdChildToParent[tokenId_child]];

        // get infor NFT parent
        uint256 NFTParent_id = tokenIdChildToParent[tokenId_child];
        string memory NFTParent_name = idToName[NFTParent_id];

        return(result_ownerAddress, NFTParent_name, NFTParent_id);
    }

    function getTotalAmountNFT() public view returns (uint256 TotalAmountNFT) {
        return listNFTs.length;
    }

    function getTotalNameNFT() public view returns (string memory TotalNameNFT) {
        string memory result = "";
        for(uint256 i = 0; i < listNFTs.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    listNFTs[i].tokenName,
                    "; "
                )
            );
        }
        return result;
    } 


    // get function to only owner
    // get list NFT parent
    function getAmountNFT() public view returns (uint256 AmountNFT) {
        return ownerToListNFT[msg.sender].length;
    }

    function getNameNFT() public view returns (string memory NameNFT) {
        NFT[] memory listNFT_exam = ownerToListNFT[msg.sender];
        string memory result = "";
        for(uint256 i = 0; i < listNFT_exam.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    listNFT_exam[i].tokenName,
                    "; "   
                )
            );
        }
        return result;
    }

    // get list NFT children
    function getTotalAmountNFTChildren() public view returns (uint256 TotalAmountNFTChildren) {
        uint256 result = 0;
        NFT[] memory listNFT_exam = ownerToListNFT[msg.sender];
        for(uint256 i = 0; i < listNFT_exam.length; i++) {
            result += tokenIdParentToListChildren[listNFT_exam[i].tokenId].length;
        }
        return result;
    } 
    
    function getAmountNFTChildren(uint256 tokenId_parent) public view returns (uint256 AmountNFTChildren) {
        require(tokenIdToOwner[tokenId_parent] == msg.sender, "This address is not allowed to call this function");
        return tokenIdParentToListChildren[tokenId_parent].length;
    }

    function getNameNFTChildren(uint256 tokenId_parent) public view returns (string memory NameNFTChildren) {
        require(tokenIdToOwner[tokenId_parent] == msg.sender, "This address is not allowed to call this function");
        CHILD[] memory listChild_exam = tokenIdParentToListChildren[tokenId_parent];
        string memory result = "";
        for(uint256 i = 0; i < listChild_exam.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    listChild_exam[i].tokenName_child,
                    "; "   
                )
            );
        }
        return result;
    } 
}