// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFTStaking is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter; //number of NFTs in circulation
    mapping(address => uint[]) idsOwned; //the ids that each person owns

    bool hasBeenFunded = false; //owner must deposit eth to be paid out
    uint funding; //amount that owner has chosen to fund the account.
    uint MAX_MINTS = 10; //max number of mints a user can create

    mapping(address => uint) numMints; //the number of mints a user has created
    mapping(address => uint) numHeld; //number of nfts held by a particular user
    mapping(address => bool) hasMintedBefore; //whether or not this is a unique address
    mapping(uint => bool) hasBeenClaimed; //whether or not a particular tokenId has already claimed their funds

    uint FUNDING_WINDOW = 864000; //funding window is 10 days -> starts after mint ends
    uint fundStart;
    uint endMint; //time when mint ends

    uint distinctHolders = 0; //number of distinct holders

    uint amountPerNFT; //funding recieved perNFT
    bool hasBeenSet; //amount Per NFT calculation must be set prior to claiming

    constructor(uint mintWindow, uint _funding) ERC721("StakeNFT", "SNFT") {
        //initializes the NFT
        endMint = block.timestamp + mintWindow;
        fundStart = endMint + FUNDING_WINDOW; //creates window for funding to be deployed
        funding = _funding;
    }

    modifier isNftOwner(uint tokenId) {
        require(ownerOf(tokenId) == msg.sender, "You do not own this token");
        _;
    }

    modifier checkSet() {
        require(
            hasBeenSet == true,
            "The owner must first call setAmountPerNFT()"
        );
        _;
    }

    function safeMint(uint numToMint) external {
        //mints tokens with parameter # mints
        require(numToMint > 0, "Number to mint needs to be atleast one");
        require(block.timestamp <= endMint, "This mint is over");
        require(numToMint <= MAX_MINTS, "You cannot mint more than 10 nfts");
        require(
            MAX_MINTS - numMints[msg.sender] >= numToMint,
            "This exceeds your maximum number of mints"
        );
        //increases distinct holders if the user has not minted before
        if (hasMintedBefore[msg.sender] == false) {
            distinctHolders += 1;
        }

        //loop to mint as many as the user wants, up to 10
        for (uint i = 0; i < numToMint; i++) {
            _tokenIdCounter.increment();
            _safeMint(msg.sender, _tokenIdCounter.current());
            idsOwned[msg.sender].push(_tokenIdCounter.current());
        }
        numHeld[msg.sender] += numToMint;
        numMints[msg.sender] += numToMint;
        hasMintedBefore[msg.sender] = true;
    }

    /// @dev fund the account so that nft holders can withdraw funds for being a holder
    function fund() public payable onlyOwner {
        require(
            hasBeenFunded == false,
            "This contract has already been funded"
        );
        require(msg.value == funding, "Value sent has to match the amount");
        hasBeenFunded = true;
    }

    /**
     *@dev transfer function with additional functionality to check things like changes in distinct holder count
     * as well as relevent mappings
     */

    function transfer(address _to, uint tokenId) external isNftOwner(tokenId) {
        _transfer(msg.sender, _to, tokenId);
        uint index = 0;
        for (uint i = 0; i < idsOwned[msg.sender].length; i++) {
            if (idsOwned[msg.sender][i] == tokenId) {
                index = i;
                break;
            }
        }
        delete idsOwned[msg.sender][index];

        idsOwned[_to].push(tokenId);

        numHeld[msg.sender] -= 1;
        numHeld[_to] += 1;

        if (numHeld[msg.sender] == 0) {
            distinctHolders -= 1;
        }

        if (numHeld[_to] == 1) {
            distinctHolders += 1;
        }
    }

    /// @dev function that must be called after account is funded and before users can claim
    /// @notice sets the amount so that it does not change after each withdrawal
    function setAmountPerNFT() public onlyOwner {
        require(hasBeenSet == false, "The amount has already been set");
        require(hasBeenFunded, "This project has not been funded");
        require(block.timestamp >= endMint, "The mint has not ended yet");
        amountPerNFT = (funding / _tokenIdCounter.current());
        hasBeenSet = true;
    }

    /// @dev getter function for testing
    function getAmountPerNFT() public view checkSet returns (uint) {
        return amountPerNFT;
    }

    /// @dev claim for users who hold nfts
    function claim(uint tokenId) public isNftOwner(tokenId) checkSet {
        require(
            hasBeenClaimed[tokenId] == false,
            "This NFT has already claimed its tokens"
        );
        (bool success, ) = payable(msg.sender).call{value: amountPerNFT}("");
        require(success, "Transfer failed");
        funding -= amountPerNFT;
    }

    /// @dev getter for distinct holders
    function getDistinctHolders() public view returns (uint) {
        return distinctHolders;
    }

    /// @dev getter for numtokens in circulation
    function getNumTokens() public view returns (uint) {
        return _tokenIdCounter.current();
    }

    /// @dev getter for the amount funded by the account;
    function getFunding() public view returns (uint) {
        return funding;
    }
}
