// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";

import { Config, TheBadge } from "./utils/Config.sol";

import { BadgeStatus } from "../src/utils.sol";

contract TheBadgeTestCore is Config {
    function test_createBadgeType_notAnEmitter() public {
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__onlyEmitter_senderIsNotAnEmitter.selector);
        theBadge.createBadgeType(badgeType, "0x");
    }

    // Test createBadgeType method by calling it from an emitter and
    // verifying that if value is lower than createBadgeTypeValue, it should revert
    function test_createBadgeType_wrongValue() public {
        vm.prank(admin);
        theBadge.updateValues(0, 0, 1 ether, 0);

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__createBadgeType_wrongValue.selector);
        theBadge.createBadgeType{ value: 0.9 ether }(badgeType, "");
    }

    // Test createBadgeType method by calling it from an emitter and
    // verifying that if the badge mint value is lower than minBadgeMintValue, it should revert
    function test_createBadgeType_lowerMintBadgeValue() public {
        vm.prank(admin);
        theBadge.updateValues(0, 0.5 ether, 0, 0);

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 0.4 ether;
        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__createBadgeType_invalidMintCost.selector);
        theBadge.createBadgeType(badgeType, "");
    }

    // Test createBadgeType method by calling it from an emitter and
    // verifying that if the the badge type controller should exists, it should revert
    function test_createBadgeType_invalidController() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.controllerName = "noController";
        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__createBadgeType_invalidController.selector);
        theBadge.createBadgeType(badgeType, "");
    }

    // Test createBadgeType method by calling it from an emitter and
    // verifying that should revert if the controller is paused
    function test_createBadgeType_controllerPaused() public {
        vm.prank(admin);
        theBadge.setControllerStatus("kleros", true);

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__createBadgeType_controllerIsPaused.selector);
        theBadge.createBadgeType(badgeType, "");
    }

    // Test createBadgeType method by calling it from an emitter and
    // verifying that it should work
    function test_createBadgeType_shouldWork() public {
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();

        vm.prank(admin);
        theBadge.updateValues(0, 0, 1 ether, 0);

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        uint256 oldBalance = feeCollector.balance;
        theBadge.createBadgeType{ value: 1 ether }(badgeType, "");
        uint256 newBalance = feeCollector.balance;

        (
            address emitter,
            string memory controllerName,
            bool paused,
            uint256 mintCost,
            uint256 mintFee,
            uint256 validFor
        ) = theBadge.badgeType(1);

        assertEq(newBalance, oldBalance + 1 ether);
        assertEq(theBadge.uri(1), "ipfs/metadataForBadge.json");
        assertEq(vegeta, emitter);
        assertEq(controllerName, badgeType.controllerName);
        assertEq(paused, false);
        assertEq(mintCost, 0);
        assertEq(mintFee, theBadge.mintBadgeDefaultFee());
        assertEq(validFor, badgeType.validFor);
    }

    // Test updateBadgeType method by calling it from an emitter and
    // verifying that it should fail if sender is not the badge emitter
    function test_updateBadgeType_notBadgeTypeOwner() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.expectRevert(TheBadge.TheBadge__updateBadgeType_notBadgeTypeOwner.selector);
        theBadge.updateBadgeType(1, 0.01 ether, 0, false);
    }

    // Test updateBadgeType method by calling it from an emitter and
    // verifying that it should fail if mintCost is lower than allowed
    function test_updateBadgeType_invalidMintCost() public {
        vm.prank(admin);
        theBadge.updateValues(0, 0.1 ether, 0, 0);

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 0.2 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__updateBadgeType_invalidMintCost.selector);
        theBadge.updateBadgeType(1, 0.01 ether, 0, false);
    }

    // Test updateBadgeType method by calling it from an emitter and
    // verifying that it should work
    function test_updateBadgeType_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        (, , bool oldPaused, uint256 oldMintCost, , ) = theBadge.badgeType(1);

        vm.prank(vegeta);
        theBadge.updateBadgeType(1, 0.01 ether, 0, true);

        (, , bool paused, uint256 mintCost, , ) = theBadge.badgeType(1);

        assertEq(oldPaused, false);
        assertEq(oldMintCost, 0);
        assertEq(paused, true);
        assertEq(mintCost, 0.01 ether);
    }

    // Test updateBadgeTypeFee method by calling it from an admin
    // to an non-existing badge-type should revert
    function test_updateBadgeTypeFee_badgeTypeNotFound() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        vm.prank(admin);
        vm.expectRevert(TheBadge.TheBadge__updateBadgeTypeFee_badgeTypeNotFound.selector);
        theBadge.updateBadgeTypeFee(777, 0);
    }

    // Test updateBadgeTypeFee method by calling it from an account not admin
    // verifying that it should revert
    function test_updateBadgeTypeFee_notAdmin() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__onlyAdmin_senderIsNotAdmin.selector);
        theBadge.updateBadgeTypeFee(1, 0);
    }

    // Test updateBadgeTypeFee method by calling it from an admin
    // to an existing badge-type should work
    function test_updateBadgeTypeFee_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        vm.prank(admin);
        theBadge.updateBadgeTypeFee(1, 0.777 ether);

        (, , , , uint256 mintFee, ) = theBadge.badgeType(1);

        assertEq(mintFee, 0.777 ether);
    }

    // Test getRequestBadgeValue method, it should return the correct cost
    // to mint the badge, including badgeType cost and strategy cost
    function test__getRequestBadgeValue_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.badgeRequestValue.selector, 1),
            abi.encode(1 ether)
        );

        assertEq(theBadge.badgeRequestValue(1), 2 ether);
    }

    // Test requestBadge by trying to mint an non-existing badge-type
    // It is expected to revert
    function test__requestBadge_nonExistingBadgeType() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.expectRevert(TheBadge.TheBadge__requestBadge_badgeTypeNotFound.selector);
        theBadge.requestBadge(777, goku, "");
    }

    // Test requestBadge by trying to mint a badge sending a different value
    // It is expected to revert
    function test__requestBadge_wrongValue() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.expectRevert(TheBadge.TheBadge__requestBadge_wrongValue.selector);
        theBadge.requestBadge(1, goku, "");
    }

    // Test requestBadge by trying to mint a badge whose controller is paused
    // It is expected to revert
    function test__requestBadge_controllerPaused() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(admin);
        theBadge.setControllerStatus("kleros", true);

        vm.prank(goku);
        vm.expectRevert(TheBadge.TheBadge__requestBadge_controllerIsPaused.selector);
        theBadge.requestBadge{ value: 1 ether }(1, goku, "");
    }

    // Test requestBadge by trying to mint a badge, it should work
    function test__requestBadge_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        uint256 vegetaOldBalance = vegeta.balance;
        uint256 feeCollectorOldBalance = feeCollector.balance;

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.requestBadge.selector, goku, 1, goku, ""),
            ""
        );
        theBadge.requestBadge{ value: 1 ether }(1, goku, "");

        (BadgeStatus status, uint256 dueDate) = theBadge.badge(1, goku);

        assertEq(vegeta.balance, vegetaOldBalance + 0.6 ether);
        assertEq(feeCollector.balance, feeCollectorOldBalance + 0.4 ether);
        assertEq(uint8(BadgeStatus.InReview), uint8(status));
        assertEq(dueDate, block.timestamp + badgeType.validFor);
    }

    // Test updateBadgeStatus by calling it from a controller didn't emit
    // the token. It should revert
    function test__updateBadgeStatus_notTheController() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.requestBadge.selector, goku, 1, goku, ""),
            ""
        );
        theBadge.requestBadge{ value: 1 ether }(1, goku, "");

        vm.prank(goku);
        vm.expectRevert(TheBadge.TheBadge__onlyController_senderIsNotTheController.selector);
        theBadge.updateBadgeStatus(1, goku, BadgeStatus.Approved);
    }

    // Test updateBadgeStatus by calling it from a controller that previously emitted
    // a token. It should work
    function test__updateBadgeStatus_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        vm.prank(vegeta);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.createBadgeType.selector, 1, ""),
            ""
        );
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        badgeType.mintCost = 1 ether;
        theBadge.createBadgeType(badgeType, "");

        vm.prank(goku);
        vm.mockCall(
            address(klerosController),
            0,
            abi.encodeWithSelector(klerosController.requestBadge.selector, goku, 1, goku, ""),
            ""
        );
        theBadge.requestBadge{ value: 1 ether }(1, goku, "");

        vm.prank(address(klerosController));
        theBadge.updateBadgeStatus(1, goku, BadgeStatus.Approved);
        (BadgeStatus status, ) = theBadge.badge(1, goku);

        assertEq(uint8(status), uint8(BadgeStatus.Approved));
    }

    function test__feeCollector_shouldWork() public {
        vm.prank(goku);
        uint256 feeCollectorOldBalance = feeCollector.balance;
        payable(address(theBadge)).transfer(1 ether);

        uint256 prevBalance = address(theBadge).balance;

        vm.prank(goku);
        theBadge.collectFees();

        assertGt(prevBalance, 0);
        assertEq(address(theBadge).balance, 0);
        assertEq(feeCollector.balance, feeCollectorOldBalance + prevBalance);
    }
}
