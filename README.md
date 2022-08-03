# NFTContractDacadeSubmission


## Description
For this project I wanted to create an NFT Minting Contract where the creator could fund the contract with money that each individual could claim depending on the number of NFTs they hold - after a certain amount of time. 

The steps to achieve that are:

1. The owner must first initialize the contract by creating a mint time period.

2. Then once the mint is over, they must fund() the contract with however much they want to reward the users. 

3. They then must call setAmountPerNFT(), which initializes variables that allow users to claim funds

4. Then users may call claim() for each NFT tokenid they own.

I added an interesting functionality around keeping track of things like distinct holders. I am not sure if most nft contracts do this but I thought it could be interesting to try.
