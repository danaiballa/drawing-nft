#drawing-nft
An example implementation of an art NFT in sui move.
##Basic functonality description
- The publisher of the contract should be the artist.
- The artist is the only entity that can mint NFT-drawings.
- Once an NFT is mint by the artist it is transferred to their address.
- The artist can sell an NFT-drawing in a [kiosk](https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/kiosk.md) and specify the price it will be sold.
- Anyone can buy an NFT from a kiosk.