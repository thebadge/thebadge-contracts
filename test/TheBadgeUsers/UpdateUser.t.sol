pragma solidity ^0.8.20;

import "../../src/contracts/libraries/LibTheBadge.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Config } from "./Config.sol";

contract UpdateUser is Config {
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

    function testRevertsUpdateUserWhenNotAdminRole() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory newMetadata = "ipfs://creatorMetadata.json";

        // TODO Fix to match the revert message
        //        vm.expectRevert(
        //            abi.encodePacked(
        //                "AccessControl: account ",
        //                StringsUpgradeable.toHexString(u1),
        //                " is missing role ",
        //                StringsUpgradeable.toHexString(uint256(0x00), 32)
        //            )
        //        );
        vm.expectRevert();

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
