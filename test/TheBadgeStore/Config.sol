pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsersStore } from "../../src/contracts/thebadge/TheBadgeUsersStore.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeUsersStore badgeUsersStore;
    TheBadgeStore badgeStore;

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeStoreProxy = Clones.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeUsersStoreProxy = Clones.clone(address(new TheBadgeUsersStore()));
        badgeUsersStore = TheBadgeUsersStore(payable(badgeUsersStoreProxy));
        badgeUsersStore.initialize(admin);
    }
}
