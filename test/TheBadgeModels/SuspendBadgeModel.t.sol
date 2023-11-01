pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Config } from "./Config.sol";

contract SuspendBadgeModel is Config {
    event BadgeModelSuspended(uint256 indexed badgeModelId, bool suspended);
    uint256 badgeModelId = 0;

    function testWorks() public {
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant PAUSER_ROLE to user
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeModels.grantRole(pauserRole, address(u1));

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

        vm.expectEmit(true, false, false, true);
        emit BadgeModelSuspended(badgeModelId, true);

        vm.prank(u1);
        badgeModels.suspendBadgeModel(badgeModelId, true);

        TheBadgeStore.BadgeModel memory _badgeModel = badgeStore.getBadgeModel(badgeModelId);
        assertEq(_badgeModel.suspended, true);
    }

    function testRevertsWhenBadgeModelNotFound() public {
        // grant PAUSER_ROLE to user
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeModels.grantRole(pauserRole, address(u1));

        vm.expectRevert(LibTheBadgeModels.TheBadge__updateBadgeModel_badgeModelNotFound.selector);

        vm.prank(u1);
        badgeModels.suspendBadgeModel(badgeModelId, true);
    }

    function testRevertsWhenNotPauserRole() public {
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, u1, pauserRole)
        );

        vm.prank(u1);
        badgeModels.suspendBadgeModel(badgeModelId, true);
    }
}
