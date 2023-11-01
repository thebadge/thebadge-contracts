pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { Config } from "./Config.sol";

contract IsBadgeModelSuspended is Config {
    function testReturnsTrueWhenSuspendedCreator() public {
        uint256 badgeModelId = 0;

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauserRole, u2);

        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // suspend user
        vm.prank(u2);
        badgeUsers.suspendUser(u1, true);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // add badge model
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(
                u1,
                "ControllerName",
                false,
                0.2e18,
                100,
                1000,
                true,
                "v1.0.0",
                false,
                1,
                false,
                "metadata"
            )
        );

        assertEq(badgeModels.isBadgeModelSuspended(badgeModelId), true);
    }

    function testReturnsFalseWhenNotSuspendedCreator() public {
        uint256 badgeModelId = 0;

        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // add badge model
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(
                u1,
                "ControllerName",
                false,
                0.2e18,
                100,
                1000,
                true,
                "v1.0.0",
                false,
                1,
                false,
                "metadata"
            )
        );

        assertEq(badgeModels.isBadgeModelSuspended(badgeModelId), false);
    }

    function testRevertsWhenNotFound() public {
        vm.expectRevert(LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound.selector);

        badgeModels.isBadgeModelSuspended(0);
    }
}
