pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadge.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";

import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { Config } from "./Config.sol";

contract SubmitUserVerification is Config {
    function testWorks() public {
        // register user
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        // fake BadgeModelController
        string memory controllerName = "KlerosBadgeModelController";
        string memory evidenceUri = "ipfs://evidence.json";
        address controller = vm.addr(5);
        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
            false,
            true
        );

        vm.prank(u1);

        // mock fuction getBadgeModelController
        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        uint256 verifyCreatorProtocolFee = 0.3 ether;

        // mock getVerifyUserProtocolFee
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IBadgeModelController.getVerifyUserProtocolFee.selector),
            abi.encode(verifyCreatorProtocolFee)
        );

        vm.expectEmit(true, true, true, true);
        emit PaymentMade(
            feeCollector,
            u1,
            verifyCreatorProtocolFee,
            LibTheBadge.PaymentType.UserVerificationFee,
            0,
            controllerName
        );

        vm.expectEmit(true, false, false, true);
        emit UserVerificationRequested(u1, evidenceUri, controllerName);

        // check submitUserVerification has been called with expected params
        vm.expectCall(
            controller,
            abi.encodeWithSelector(IBadgeModelController.submitUserVerification.selector, u1, metadata, evidenceUri)
        );

        badgeUsers.submitUserVerification{ value: verifyCreatorProtocolFee }(controllerName, evidenceUri);
    }

    function testRevertsWhenBadgeModelControllerInvalid() public {
        // register user
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory controllerName = "KlerosBadgeModelController";
        string memory evidenceUri = "ipfs://evidence.json";

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            address(0),
            false,
            false
        );

        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        vm.prank(u1);
        vm.expectRevert(LibTheBadge.TheBadge__controller_invalidController.selector);
        badgeUsers.submitUserVerification(controllerName, evidenceUri);
    }

    function testRevertsWhenNotRegisteredUser() public {
        string memory controllerName = "KlerosBadgeModelController";
        string memory evidenceUri = "ipfs://evidence.json";

        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyUser_userNotFound.selector);
        vm.prank(u1);
        badgeUsers.submitUserVerification(controllerName, evidenceUri);
    }

    function testRevertsWhenWrongValue() public {
        // register user
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        // fake BadgeModelController
        string memory controllerName = "KlerosBadgeModelController";
        string memory evidenceUri = "ipfs://evidence.json";
        address controller = vm.addr(5);
        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
            false,
            true
        );

        // mock fuction getBadgeModelController
        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.getBadgeModelController.selector),
            abi.encode(badgeModelController)
        );

        uint256 verifyCreatorProtocolFee = 0.3 ether;

        // mock getVerifyUserProtocolFee
        vm.mockCall(
            controller,
            abi.encodeWithSelector(IBadgeModelController.getVerifyUserProtocolFee.selector),
            abi.encode(verifyCreatorProtocolFee)
        );

        vm.expectRevert(LibTheBadgeUsers.TheBadge__verifyUser_wrongValue.selector);

        vm.prank(u1);
        badgeUsers.submitUserVerification{ value: 0.1 ether }(controllerName, evidenceUri);
    }
}
