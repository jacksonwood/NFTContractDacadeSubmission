# NFTContractDacadeSubmission

For this project I wanted to create an NFT Minting Contract where the creator could fund the contract with money that each individual could claim depending on the number of NFTs they hold - after a certain amount of time. 

The owner must first initialize the contract by creating a mint time period.

Then once the mint is over, they must fund() the contract with however much they want to reward the users. 

They then must call setAmountPerNFT(), which initializes variables that allow users to claim funds

Then users may call claim() for each NFT tokenid they own.

I added interesting functionality around keeping track of things like distinct holders. I am not sure if most nft contracts do this but I thought it could be interesting to try.
