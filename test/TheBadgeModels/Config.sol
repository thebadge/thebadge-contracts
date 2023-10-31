pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../../src/contracts/thebadge/TheBadgeUsers.sol";
import { TheBadgeModels } from "../../src/contracts/thebadge/TheBadgeModels.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeStore badgeStore;
    TheBadgeUsers badgeUsers;
    TheBadgeModels badgeModels;

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeStoreProxy = Clones.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeUsersProxy = Clones.clone(address(new TheBadgeUsers()));
        badgeUsers = TheBadgeUsers(payable(badgeUsersProxy));
        badgeUsers.initialize(admin, badgeStoreProxy);

        address badgeModelsProxy = Clones.clone(address(new TheBadgeModels()));
        badgeModels = TheBadgeModels(payable(badgeModelsProxy));
        badgeModels.initialize(admin, badgeStoreProxy, badgeUsersProxy);

        vm.startPrank(admin);
        badgeStore.addPermittedContract("TheBadgeModels", badgeModelsProxy);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersProxy);
        vm.stopPrank();
    }
}
