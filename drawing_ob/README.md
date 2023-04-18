# Info
In order for the contract to build the [OriginByte nft protocol](https://github.com/Origin-Byte/nft-protocol) should be downloaded and put one directory outside of the `drawing_ob/Move.toml` file.
That is because in the Move.toml file we have in the dependencies
```
[dependencies.NftProtocol]
local = "../nft-protocol"
```
