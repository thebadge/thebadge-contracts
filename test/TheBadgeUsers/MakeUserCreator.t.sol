pragma solidity ^0.8.20;

import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract MakeUserCreator is Config {
    function testMakeUserCreator() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        vm.expectEmit(true, false, false, true);
        emit UpdatedUser(u1, metadata, false, true, false);
        badgeUsers.makeUserCreator(u1);

        (, , bool _isCreator, , ) = badgeUsersStore.registeredUsers(u1);

        assertEq(_isCreator, true);
    }

    function testRevertsMakeUserCreatorWhenUserNotFound() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.makeUserCreator(u1);
    }

    function testRevertsMakeUserCreatorWhenUserAlreadyCreator() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        badgeUsers.makeUserCreator(u1);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyCreator_senderIsAlreadyACreator.selector);
        badgeUsers.makeUserCreator(u1);
    }
}
