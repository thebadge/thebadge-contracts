pragma solidity ^0.8.20;

import "../../src/contracts/libraries/LibTheBadge.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Config } from "./Config.sol";

contract UpdateUser is Config {
    bytes32 adminRole = 0x00;
    bytes32 userManagerRole = keccak256("USER_MANAGER_ROLE");

    function testUpdateUser() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.prank(admin);

        vm.expectEmit(true, false, false, true);
        emit UpdatedUser(u1, newMetadata, false, false, false);

        badgeUsers.updateUser(u1, newMetadata);

        (string memory _metadata, , , , ) = badgeStore.registeredUsers(u1);

        assertEq(_metadata, newMetadata);
    }

    function testRevertsUpdateUserWhenNotUserManagerRole() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, u1, userManagerRole)
        );

        vm.prank(u1);
        badgeUsers.updateUser(u1, newMetadata);
    }

    function testRevertsUpdateUserWhenUserNotFound() public {
        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.prank(admin);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.updateUser(u1, newMetadata);
    }
}
