pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsersStore } from "../../src/contracts/thebadge/TheBadgeUsersStore.sol";
import { TheBadgeUsers } from "../../src/contracts/thebadge/TheBadgeUsers.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { ITheBadgeUsers } from "../../src/interfaces/ITheBadgeUsers.sol";
import { Config } from "./Config.sol";

contract ExecuteUserVerification is Config {
    event UserVerificationExecuted(address indexed user, string controllerName, bool verify);

    bytes32 verifierRole = keccak256("VERIFIER_ROLE");

    function testWorks() public {
        // grant role
        vm.prank(admin);
        badgeUsers.grantRole(verifierRole, u2);

        // register user
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory controllerName = "KlerosBadgeModelController";

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            address(klerosBadgeModelControllerInstance),
            false,
            true
        );

        // mock function getBadgeModelController
        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        // mock function executeUserVerification
        vm.mockCall(
            address(klerosBadgeModelControllerInstance),
            abi.encodeWithSelector(TheBadgeUsersStore.updateUserVerificationStatus.selector),
            abi.encode(true)
        );

        // Submits the testRevertsWhenVerificationNotStarted(
        vm.prank(u1);
        badgeUsers.submitUserVerification{ value: 0 }(controllerName, metadata);

        // check executeUserVerification has been called with expected params
        vm.expectCall(
            address(badgeUsers),
            abi.encodeWithSelector(ITheBadgeUsers.executeUserVerification.selector, u1, controllerName, true)
        );

        vm.expectEmit(true, false, false, true);
        emit UserVerificationExecuted(u1, controllerName, true);

        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, controllerName, true);
    }

    function testRevertsWhenWrongRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, u2, verifierRole)
        );
        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, "KlerosBadgeModelController", true);
    }

    function testRevertsWhenBadgeModelControllerInvalid() public {
        // grant role
        vm.prank(admin);
        badgeUsers.grantRole(verifierRole, u2);

        vm.expectRevert(LibTheBadge.TheBadge__controller_invalidController.selector);

        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, "KlerosBadgeModelController", true);
    }

    function testRevertsWhenUserNotRegistered() public {
        // grant role
        vm.prank(admin);
        badgeUsers.grantRole(verifierRole, u2);

        string memory controllerName = "KlerosBadgeModelController";

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            address(klerosBadgeModelControllerInstance),
            false,
            true
        );

        // mock function getBadgeModelController
        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyUser_userNotFound.selector);

        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, controllerName, true);
    }

    function testRevertsWhenVerificationNotStarted() public {
        // grant role
        vm.prank(admin);
        badgeUsers.grantRole(verifierRole, u2);

        // register user
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory controllerName = "KlerosBadgeModelController";

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            address(klerosBadgeModelControllerInstance),
            false,
            true
        );

        // mock function getBadgeModelController
        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        // mock function executeUserVerification
        vm.mockCall(
            address(klerosBadgeModelControllerInstance),
            abi.encodeWithSelector(TheBadgeUsersStore.updateUserVerificationStatus.selector),
            abi.encode(true)
        );

        // check executeUserVerification has been called with expected params
        vm.expectCall(
            address(badgeUsers),
            abi.encodeWithSelector(ITheBadgeUsers.executeUserVerification.selector, u1, controllerName, true)
        );

        vm.expectRevert(LibTheBadgeUsers.TheBadge__verifyUser__userVerificationNotStarted.selector);
        emit UserVerificationExecuted(u1, controllerName, true);

        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, controllerName, true);
    }
}
