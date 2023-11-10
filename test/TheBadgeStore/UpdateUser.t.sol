pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract UpdateUser is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        TheBadgeStore.User memory user = TheBadgeStore.User("ipfs://metadata.json", false, false, false, true);

        vm.prank(badgeUsersAddress);
        badgeStore.createUser(u1, user);

        string memory newMetadata = "ipfs://metadata.edited.json";
        bool newIsCompany = true;
        bool newIsCreator = true;
        bool newSuspended = true;
        bool newInitialized = true;
        TheBadgeStore.User memory newUser = TheBadgeStore.User(
            newMetadata,
            newIsCompany,
            newIsCreator,
            newSuspended,
            newInitialized
        );

        vm.prank(badgeUsersAddress);
        badgeStore.updateUser(u1, newUser);

        (string memory _metadata, bool _isCompany, bool _isCreator, bool _suspended, bool _initialized) = badgeStore
            .registeredUsers(u1);

        assertEq(_metadata, newMetadata);
        assertEq(_isCompany, newIsCompany);
        assertEq(_isCreator, newIsCreator);
        assertEq(_suspended, newSuspended);
        assertEq(_initialized, newInitialized);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        string memory metadata = "ipfs://metadata.json";
        TheBadgeStore.User memory user = TheBadgeStore.User(metadata, false, false, false, false);

        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        vm.prank(badgeUsersAddress);
        badgeStore.updateUser(u1, user);
    }

    function testRevertsWhenUserNotFound() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        TheBadgeStore.User memory newUser = TheBadgeStore.User("ipfs://metadata.edited.json", true, true, true, true);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        vm.prank(badgeUsersAddress);
        badgeStore.updateUser(u1, newUser);
    }
}
