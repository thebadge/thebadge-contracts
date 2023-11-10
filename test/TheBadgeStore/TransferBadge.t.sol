pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract TransferBadge is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);
        uint256 badgeModelId = 2;
        uint256 badge1 = 0;
        uint256 badge2 = 1;

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        vm.prank(badgeUsersAddress);
        badgeStore.addBadge(badge1, TheBadgeStore.Badge(badgeModelId, u1, 111, true));

        vm.prank(badgeUsersAddress);
        badgeStore.addBadge(badge2, TheBadgeStore.Badge(badgeModelId, u1, 222, true));

        // User1 should have two badges
        uint256[] memory user1Badges = badgeStore.getUserMintedBadgesByBadgeModel(badgeModelId, u1);
        assertEq(user1Badges.length, 2);

        // User2 should have 0 badges
        uint256[] memory user2Badges = badgeStore.getUserMintedBadgesByBadgeModel(badgeModelId, u2);
        assertEq(user2Badges.length, 0);

        // TRANSFERS the badge2 from user1 to user2
        vm.prank(badgeUsersAddress);
        badgeStore.transferBadge(badge2, u1, u2);

        // User1 should have one badge
        uint256[] memory user1BadgesPostTransfer = badgeStore.getUserMintedBadgesByBadgeModel(badgeModelId, u1);
        assertEq(user1BadgesPostTransfer.length, 1);

        // User2 should have 1 badge
        uint256[] memory user2BadgesPostTransfer = badgeStore.getUserMintedBadgesByBadgeModel(badgeModelId, u2);
        assertEq(user2BadgesPostTransfer.length, 1);

        // The first badge should still exists on the user1
        uint256 _badgeIdFrom = badgeStore.userMintedBadgesByBadgeModel(badgeModelId, u1, 0);
        assertEq(_badgeIdFrom, badge1);

        // The second badge should not exists anymore on the user1
        vm.expectRevert();
        badgeStore.userMintedBadgesByBadgeModel(badgeModelId, u1, 1);

        // The second badge should be now on the user2
        uint256 _badgeIdTo = badgeStore.userMintedBadgesByBadgeModel(badgeModelId, u2, 0);
        assertEq(_badgeIdTo, badge2);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);

        badgeStore.transferBadge(0, u1, u2);
    }
}
