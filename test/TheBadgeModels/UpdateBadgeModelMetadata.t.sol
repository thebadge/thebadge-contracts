pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { KlerosBadgeModelController } from "../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { TpBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";
import { Config } from "./Config.sol";

contract UpdateBadgeModelMetadata is Config {
    event BadgeModelUpdated(uint256 indexed badgeModelId);
    event BadgeModelVersionUpdated(
        uint256 indexed badgeModelId,
        uint256 indexed newBadgeModelId,
        uint256 indexed version
    );
    uint256 badgeModelId = 0;
    string newMetadata = "ipfs://newMetadata";
    bytes data = "0x";

    function testWorksWithMetadataUpdatable() public {
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        vm.startPrank(address(badgeModels));

        // Adds a badgeModel
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(
                u1,
                klerosControllerName,
                false,
                0.2e18,
                100,
                1000,
                true,
                1,
                false,
                false,
                "metadata"
            )
        );

        badgeUsers.makeUserCreator(u1);
        vm.stopPrank();

        vm.expectEmit(true, false, false, true);
        emit BadgeModelUpdated(badgeModelId);

        vm.prank(u1);
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);

        TheBadgeStore.BadgeModel memory _badgeModel = badgeStore.getBadgeModel(badgeModelId);

        assertEq(_badgeModel.metadata, newMetadata);
    }

    function testWorksWithMetadataNotUpdatable() public {
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // Register the user as third party one
        vm.prank(u1);
        badgeUsers.submitUserVerification(tpControllerName, "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsers.executeUserVerification(u1, tpControllerName, true);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // vm.startPrank(address(badgeModels));
        vm.prank(u1);

        // Adds a badgeModel
        uint256 fee = 0.1e18;

        // Create an array with a single element containing the address
        TpBadgeModelControllerStore.CreateBadgeModel memory badgeModelData = TpBadgeModelControllerStore
            .CreateBadgeModel(new address[](0), "ipfs://requirementsIPFSHash.json");

        // Encode the struct into bytes
        bytes memory dataTp = abi.encode(badgeModelData);

        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: tpControllerName,
            mintCreatorFee: 0.2e18,
            validFor: 100
        });
        badgeModels.createBadgeModel{ value: fee }(args, dataTp);

        uint256 newBadgeModelId = badgeModelId + 1;
        uint256 newModelVersion = 2;

        vm.expectEmit(true, false, false, true);
        emit BadgeModelVersionUpdated(badgeModelId, newBadgeModelId, newModelVersion);

        vm.prank(u1);
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, dataTp);

        // Verifies that the old badgeModel was deprecated
        TheBadgeStore.BadgeModel memory _badgeModel = badgeStore.getBadgeModel(badgeModelId);
        assertEq(_badgeModel.deprecated, true);
        assertEq(_badgeModel.metadata, "metadata");

        // Verifies that a new badgeModel was created
        TheBadgeStore.BadgeModel memory _newBadgeModel = badgeStore.getBadgeModel(newBadgeModelId);
        assertEq(_newBadgeModel.deprecated, false);
        assertEq(_badgeModel.creator, _newBadgeModel.creator);
        assertEq(_newBadgeModel.metadata, newMetadata);
        assertEq(_badgeModel.initialized, _newBadgeModel.initialized);
        assertEq(_badgeModel.suspended, _newBadgeModel.suspended);
        assertEq(_badgeModel.paused, _newBadgeModel.paused);
        assertEq(_badgeModel.controllerName, _newBadgeModel.controllerName);
        assertEq(_badgeModel.validFor, _newBadgeModel.validFor);
        assertEq(_badgeModel.mintProtocolFee, _newBadgeModel.mintProtocolFee);
        assertEq(_badgeModel.mintCreatorFee, _newBadgeModel.mintCreatorFee);
    }

    function testRevertsWhenNotCreator() public {
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyCreator_senderIsNotACreator.selector);

        vm.prank(u1);
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
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
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
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
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
    }

    function testRevertsWhenBadgeModelNotUpgradable() public {
        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // make user creator
        vm.startPrank(address(badgeModels));
        badgeUsers.makeUserCreator(u1);

        // Adds a badgeModel
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(
                u1,
                klerosControllerName,
                false,
                0.2e18,
                100,
                1000,
                true,
                1,
                false,
                false,
                "metadata"
            )
        );
        vm.stopPrank();

        vm.mockCall(
            address(klerosBadgeModelControllerInstance),
            abi.encodeWithSelector(KlerosBadgeModelController.isBadgeModelMetadataUpgradeable.selector),
            abi.encode(false)
        );

        vm.expectRevert(LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotUpgradeable.selector);

        vm.prank(u1);
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
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
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
    }

    function testRevertsWhenOwnerIsSuspended() public {
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

        // grant PAUSER_ROLE to badgeModels
        bytes32 pauserRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauserRole, address(admin));

        // make user creator
        vm.prank(address(badgeModels));
        badgeUsers.makeUserCreator(u2);

        // Suspend user
        vm.prank(address(admin));
        badgeUsers.suspendUser(u2, true);

        vm.expectRevert(LibTheBadgeUsers.TheBadge__users__onlyCreator_creatorIsSuspended.selector);

        vm.prank(u2);
        badgeModels.updateBadgeModelMetadata(badgeModelId, newMetadata, data);
    }
}
