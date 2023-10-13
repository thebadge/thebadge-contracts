pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract AddBadge is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        uint256 badgeModelId = 0;
        address account = vm.addr(11);
        uint256 dueDate = 100;
        bool initialized = true;

        TheBadgeStore.Badge memory badge = TheBadgeStore.Badge(badgeModelId, account, dueDate, initialized);

        vm.prank(badgeUsersAddress);
        badgeStore.addBadge(0, badge);

        (uint256 _badgeModelId, address _account, uint256 _dueDate, bool _initialized) = badgeStore.badges(0);

        assertEq(_badgeModelId, badgeModelId);
        assertEq(_account, account);
        assertEq(_dueDate, dueDate);
        assertEq(_initialized, initialized);

        uint256 counter = badgeStore.getCurrentBadgeIdCounter();

        assertEq(counter, 1);

        uint256 _badgeId = badgeStore.userMintedBadgesByBadgeModel(badgeModelId, account, 0);

        assertEq(_badgeId, 0);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        uint256 badgeModelId = 0;
        address account = vm.addr(11);
        uint256 dueDate = 100;
        bool initialized = true;

        TheBadgeStore.Badge memory badge = TheBadgeStore.Badge(badgeModelId, account, dueDate, initialized);

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.addBadge(0, badge);
    }
}
