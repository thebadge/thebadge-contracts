pragma solidity ^0.8.20;

import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract SuspendUser is Config {
    function testSuspendUser() public {
        bytes32 pauseRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauseRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        badgeUsers.suspendUser(u1, true);

        (, , , bool _suspended, ) = badgeStore.registeredUsers(u1);

        assertEq(_suspended, true);
    }

    function testRevertsSuspendUserWhenUserNotFound() public {
        bytes32 pauseRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauseRole, u2);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.suspendUser(u1, true);
    }
}
