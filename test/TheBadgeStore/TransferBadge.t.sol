pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract TransferBadge is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        vm.prank(badgeUsersAddress);
        badgeStore.addBadge(0, TheBadgeStore.Badge(2, u1, 111, true));

        vm.prank(badgeUsersAddress);
        badgeStore.addBadge(1, TheBadgeStore.Badge(2, u1, 222, true));

        vm.prank(badgeUsersAddress);
        badgeStore.transferBadge(1, u1, u2);

        uint256 _badgeIdFrom = badgeStore.userMintedBadgesByBadgeModel(2, u1, 1);
        assertEq(_badgeIdFrom, 0);

        uint256 _badgeIdTo = badgeStore.userMintedBadgesByBadgeModel(2, u2, 0);
        assertEq(_badgeIdTo, 1);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);

        badgeStore.transferBadge(0, u1, u2);
    }
}
