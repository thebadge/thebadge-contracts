// SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadge } from "../../src/contracts/thebadge/TheBadge.sol";


contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeStore badgeStore;
    TheBadge badge;

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(u2, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeStoreProxy = Clones.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeProxy = Clones.clone(address(new TheBadge()));
        badge = TheBadge(payable(badgeProxy));
        badge.initialize(admin, badgeStoreProxy);
    }
}