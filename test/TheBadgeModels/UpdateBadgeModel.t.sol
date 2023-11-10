pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { Config } from "./Config.sol";

contract UpdateBadgeModel is Config {
    event BadgeModelUpdated(uint256 indexed badgeModelId);

    function testWorks() public {
        uint256 badgeModelId = 0;
        uint256 mintCreatorFee = 0.1e18;

        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        vm.startPrank(address(badgeModels));
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(u1, "ControllerName", false, 0.2e18, 100, 1000, true, 1, false, false, "metadata")
        );

        badgeUsers.makeUserCreator(u1);
        vm.stopPrank();

        vm.expectEmit(true, false, false, true);
        emit BadgeModelUpdated(badgeModelId);

        vm.prank(u1);
        badgeModels.updateBadgeModel(badgeModelId, mintCreatorFee, true);

        TheBadgeStore.BadgeModel memory _badgeModel = badgeStore.getBadgeModel(badgeModelId);

        assertEq(_badgeModel.mintCreatorFee, mintCreatorFee);
        assertEq(_badgeModel.paused, true);
    }

    function testRevertsWhenNotCreator() public {
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyCreator_senderIsNotACreator.selector);

        vm.prank(u1);
        badgeModels.updateBadgeModel(0, 0.1e18, true);
    }

    function testRevertsWhenSuspendedCreator() public {
        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // make user creator
        vm.prank(address(badgeModels));
        badgeUsers.makeUserCreator(u1);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauserRole, u2);

        // suspend user
        vm.prank(u2);
        badgeUsers.suspendUser(u1, true);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__users__onlyCreator_creatorIsSuspended.selector);

        vm.prank(u1);
        badgeModels.updateBadgeModel(0, 0.1e18, true);
    }

    function testRevertsWhenBadgeModelNotFound() public {
        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // make user creator
        vm.prank(address(badgeModels));
        badgeUsers.makeUserCreator(u1);

        vm.expectRevert(LibTheBadgeModels.TheBadge__updateBadgeModel_badgeModelNotFound.selector);

        vm.prank(u1);
        badgeModels.updateBadgeModel(0, 0.1e18, true);
    }

    function testRevertsWhenNotOwner() public {
        // add badge model
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(u1, "ControllerName", false, 0.2e18, 100, 1000, true, 1, false, false, "metadata")
        );

        // register user
        vm.prank(u2);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // make user creator
        vm.prank(address(badgeModels));
        badgeUsers.makeUserCreator(u2);

        vm.expectRevert(LibTheBadgeModels.TheBadge__updateBadgeModel_notBadgeModelOwner.selector);

        vm.prank(u2);
        badgeModels.updateBadgeModel(0, 0.1e18, true);
    }
}
