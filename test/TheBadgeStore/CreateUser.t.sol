pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract CreateUser is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeStore.User memory user = TheBadgeStore.User(metadata, false, false, false, false);

        vm.prank(badgeUsersAddress);
        badgeStore.createUser(u1, user);

        (string memory _metadata, bool _isCompany, bool _isCreator, bool _suspended, bool _initialized) = badgeStore
            .registeredUsers(u1);

        assertEq(_metadata, metadata);
        assertEq(_isCompany, false);
        assertEq(_isCreator, false);
        assertEq(_suspended, false);
        assertEq(_initialized, false);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeStore.User memory user = TheBadgeStore.User(metadata, false, false, false, false);

        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        vm.prank(badgeUsersAddress);
        badgeStore.createUser(u1, user);
    }

    function testRevertsWhenUserAlreadyRegistered() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeStore.User memory user = TheBadgeStore.User(metadata, false, false, false, false);

        vm.prank(badgeUsersAddress);
        badgeStore.createUser(u1, user);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered.selector);
        vm.prank(badgeUsersAddress);
        badgeStore.createUser(u1, user);
    }
}
