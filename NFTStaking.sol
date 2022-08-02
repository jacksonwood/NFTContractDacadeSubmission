// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTStaking is ERC721, Ownable {

    uint tokenId = 0; //number of NFTs in circulation
    mapping(address => uint[]) idsOwned; //the ids that each person owns

    bool hasBeenFunded = false; //owner must deposit eth to be paid out
    uint funding = 0; //amount that owner has chosen to fund the account.
    uint MAX_MINTS = 10; //max number of mints a user can create

    mapping(address => uint) numMints; //the number of mints a user has created
    mapping(address => uint) numHeld; //number of nfts held by a particular user
    mapping(address => bool) hasMintedBefore; //whether or not this is a unique address
    mapping(uint => bool) hasBeenClaimed; //whether or not a particular tokenId has already claimed their funds
    mapping(uint => address) ownedBy; //the owner of a particular tokenId

    uint FUNDING_WINDOW = 864000; //funding window is 10 days -> starts after mint ends
    uint fundStart;
    uint endMint; //time when mint ends

    uint distinctHolders = 0; //number of distinct holders
    
    uint amountPerNFT; //funding recieved perNFT
    bool hasBeenSet; //amount Per NFT calculation must be set prior to claiming

    constructor(uint mintWindow) ERC721("StakeNFT", "SNFT") { //initializes the NFT
        endMint = block.timestamp + mintWindow;
        fundStart = endMint + FUNDING_WINDOW; //creates window for funding to be deployed
    }

    function safeMint(uint numToMint) public { //mints tokens with parameter # mints
        require(block.timestamp <= endMint, "This mint is over");
        require(numToMint <= MAX_MINTS, "You cannot mint more than 10 nfts");
        require(MAX_MINTS - numMints[msg.sender] >= numToMint, "This exceeds your maximum number of mints");
        //increases distinct holders if the user has not minted before
        if (hasMintedBefore[msg.sender] == false) {
            distinctHolders += 1;
        }

        //loop to mint as many as the user wants, up to 10
        for (uint i = 0; i < numToMint; i++) {
            _safeMint(msg.sender, tokenId);
            numMints[msg.sender] += 1;
            numHeld[msg.sender] += 1;
            idsOwned[msg.sender].push(tokenId);
            ownedBy[tokenId] = msg.sender;
            tokenId++;
        }

        hasMintedBefore[msg.sender] = true;
    }

    //fund the account so that nft holders can withdraw funds for being a holder
    function fund(uint amount) public payable onlyOwner {
        require(hasBeenFunded == false, "This contract has already been funded");
        funding += amount;
        hasBeenFunded = true;
    }

    //transfer function with additional functionality to check things like changes in distinct holder count
    //as well as relevent mappings
    function transfer(address _to, uint _tokenId) public {
        require(ownedBy[_tokenId] == msg.sender, "You do not own this token");
        safeTransferFrom(msg.sender, _to, _tokenId);
        uint index = 0;
        for (uint i = 0; i < idsOwned[msg.sender].length; i++){
            if (idsOwned[msg.sender][i] == _tokenId) {
                index = i;
            }
        }
        delete idsOwned[msg.sender][index];
        
        idsOwned[_to].push(_tokenId);
        
        numHeld[msg.sender] -= 1;
        numHeld[_to] += 1;

        ownedBy[_tokenId] = _to;

        if (numHeld[msg.sender] == 0) {
            distinctHolders -= 1;
        }

        if (numHeld[_to] == 1) {
            distinctHolders += 1;
        }
    }

    //function that must be called after account is funded and before users can claim
    //sets the amount so that it does not change after each withdrawal
    function setAmountPerNFT() public onlyOwner {
        require(hasBeenSet == false, "The amount has already been set");
        require(hasBeenFunded, "This project has not been funded");
        require(block.timestamp >= endMint, "The mint has not ended yet");
        amountPerNFT = (funding / tokenId);
        hasBeenSet = true;
    }

    //getter function for testing
    function getAmountPerNFT() public view returns (uint) {
        require(hasBeenSet == true, "The owner must first call setAmountPerNFT()");
        return amountPerNFT;
    }

    //claim for users who hold nfts
    function claim(uint _tokenId) public {
        require(hasBeenSet == true, "The owner must first call setAmountPerNFT()");
        require(hasBeenClaimed[_tokenId] == false, "This NFT has already claimed its tokens");
        require(ownedBy[_tokenId] == msg.sender, "You do not own this NFT");
        payable(msg.sender).transfer(amountPerNFT);
        funding -= amountPerNFT;
    }

    //getter for distinct holders
    function getDistinctHolders() public view returns (uint) {
        return distinctHolders;
    }


    //getter for numtokens in circulation
    function getNumTokens() public view returns (uint) {
        return tokenId;
    }


    //getter for the amount funded by the account;
    function getFunding() public view returns (uint) {
        return funding;
    }
}
