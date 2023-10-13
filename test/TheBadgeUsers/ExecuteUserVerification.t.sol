pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadge.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
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

        address controller = vm.addr(5);
        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
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
            controller,
            abi.encodeWithSelector(IBadgeModelController.executeUserVerification.selector),
            abi.encode(true)
        );

        // check executeUserVerification has been called with expected params
        vm.expectCall(
            controller,
            abi.encodeWithSelector(IBadgeModelController.executeUserVerification.selector, u1, true)
        );

        vm.expectEmit(true, false, false, true);
        emit UserVerificationExecuted(u1, controllerName, true);

        vm.prank(u2);
        badgeUsers.executeUserVerification(u1, controllerName, true);
    }

    function testRevertsWhenWrongRole() public {
        // TODO Fix expect revert message
//        vm.expectRevert(
//            abi.encodePacked(
//                "AccessControl: account ",
//                Strings.toHexString(u2),
//                " is missing role ",
//                Strings.toHexString(uint256(verifierRole), 32)
//            )
//        );
        vm.expectRevert();
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

        address controller = vm.addr(5);
        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
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
}
