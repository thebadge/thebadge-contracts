pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeStore badgeStore;

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeStoreProxy = ClonesUpgradeable.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);
    }
}
