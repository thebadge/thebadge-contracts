## The badge smart contract methods

### SetBadgeModelController and setControllerStatus

- SetBadgeModelController: this is who is going to controll this badge model
- setControllerStatus: it is to pause or resume a controller

## Methods from SC The badge

![method1.png](..%2Fassets%2Fimages%2Fmethod1.png)

### RegisterBadgeModelCreator

- This method is to register a badge model creator, this is who is going to create a badge model

![method2.png](..%2Fassets%2Fimages%2Fmethod2.png)

### Update Badge Model Fee and balance Of Badge Model

- This method is to update the fee of a badge model, in order to have the posibility to change the fee of a badge model if the badge model creator wants to do it
- This works to know the balance of a badge model

![method4.png](..%2Fassets%2Fimages%2Fmethod4.png)

### Create Badge Model

- One of the most important methods, this is to create a badge model, this method is going to create a badge model describing all the characteristics that something needs to have in order to get a badge

![method5.png](..%2Fassets%2Fimages%2Fmethod5.png)

### Update Badge Model creator and mint

- two different methods.
- We can update the badge model creato checking that this badge model creator is registered
- We can mint a badge if we have the badge model id, the receiver address and the data of the badge

![method6.png](..%2Fassets%2Fimages%2Fmethod6.png)

### Update badge model

- If the badge model exist, we can update it.

![method7.png](..%2Fassets%2Fimages%2Fmethod7.png)

### Contacts

[TheBadge docs](https://docs.thebadge.xyz/thebadge-documentation/)

[TheBadge.sol](https://github.com/thebadge/thebadge-contracts/blob/v2/src/TheBadge.sol)

[IBadgeController (Kleros.sol)](https://github.com/thebadge/thebadge-contracts/blob/v2/src/badgeModelControllers/kleros.sol)

[LightGeneralizedTCR.sol](https://github.com/kleros/tcr/blob/72e547ea135d839dc5db34e79e9f94f05c6a92bb/contracts/LightGeneralizedTCR.sol)

[ERC1155.sol](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC1155/ERC1155.sol)
