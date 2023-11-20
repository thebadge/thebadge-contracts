pragma solidity ^0.8.20;

import { TheBadgeUsersStore } from "../../src/contracts/thebadge/TheBadgeUsersStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract CreateUser is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeUsersStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeUsersStore.User memory user = TheBadgeUsersStore.User(metadata, false, false, false, false);

        vm.prank(badgeUsersAddress);
        badgeUsersStore.createUser(u1, user);

        (
            string memory _metadata,
            bool _isCompany,
            bool _isCreator,
            bool _suspended,
            bool _initialized
        ) = badgeUsersStore.registeredUsers(u1);

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
        TheBadgeUsersStore.User memory user = TheBadgeUsersStore.User(metadata, false, false, false, false);

        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        vm.prank(badgeUsersAddress);
        badgeUsersStore.createUser(u1, user);
    }

    function testRevertsWhenUserAlreadyRegistered() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeUsersStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeUsersStore.User memory user = TheBadgeUsersStore.User(metadata, false, false, false, true);

        vm.prank(badgeUsersAddress);
        badgeUsersStore.createUser(u1, user);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered.selector);
        vm.prank(badgeUsersAddress);
        badgeUsersStore.createUser(u1, user);
    }
}
