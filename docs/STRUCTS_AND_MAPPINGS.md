## Structs and mappings

### Structs:

- `structs` are a way to group related data together.
- This `structs` are related with The Badge smart contract and it business logic.
- An example The Badge smart contract has 2 structs:
  - `BadgeModel`
  - `Badge`

```solidity
struct BadgeModel {
  string name;
  string description;
  string image;
  uint256 price;
  uint256 totalSupply;
  uint256 maxSupply;
  uint256 minted;
  bool paused;
  bool exists;
}
```

### Mappings:

- `mappings` are a way to store data in key-value pairs.
- This `mappings` are related with The Badge smart contract and it business logic.
- An example The Badge smart contract has 2 mappings:
  - `badgeModels`
  - `badges`

```solidity
mapping(uint256 => BadgeModel) public badgeModels;
mapping(uint256 => Badge) public badges;
```

### Structs and mappings in The Badge smart contract

![structs_and_mappings.png](..%2Fassets%2Fimages%2Fstructs_and_mappings.png)

### Contacts

[TheBadge docs](https://docs.thebadge.xyz/thebadge-documentation/)
