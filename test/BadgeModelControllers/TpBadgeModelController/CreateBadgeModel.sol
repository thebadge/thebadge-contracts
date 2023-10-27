pragma solidity ^0.8.20;

import { TheBadgeModels } from "../../../src/contracts/thebadge/TheBadgeModels.sol"; // Use the appropriate Solidity version
import { TheBadgeStore } from "../../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../../../src/contracts/thebadge/TheBadgeUsers.sol";
import { TpBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";
import { ILightGeneralizedTCR } from "../../../src/interfaces/ILightGeneralizedTCR.sol";
import { Config } from "./Config.sol";
import "forge-std/console.sol";

contract CreateBadgeModel is Config {
    string private controllerName = "thirdParty";
    uint256 private mintCreatorFee = 100;
    uint256 private validFor = 365 days;

    function testCreateThirdPartyBadgeModel() public {
        // Register a user
        vm.prank(user1);
        badgeUsersInstance.registerUser("ipfs://creatorMetadata.json", false);

        // Register the user as third party one
        vm.prank(user1);
        badgeUsersInstance.submitUserVerification("thirdParty", "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsersInstance.executeUserVerification(user1, "thirdParty", true);

        // Create a badge model
        TheBadgeStore.CreateBadgeModel memory badgeModel = TheBadgeStore.CreateBadgeModel({
            metadata: "ipfs://badgeModelMetadata.json",
            controllerName: controllerName,
            mintCreatorFee: mintCreatorFee, // Adjust fee as needed
            validFor: validFor // Adjust validity period as needed
        });

        address[] memory administrators = new address[](1);
        administrators[0] = user1;
        TpBadgeModelControllerStore.CreateBadgeModel memory tpBadgeModel = TpBadgeModelControllerStore
            .CreateBadgeModel({ administrators: administrators });

        bytes memory data = abi.encode(tpBadgeModel);

        uint256 initialBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform the createBadgeModel transaction
        {
            vm.prank(user1);
            badgeModelsInstance.createBadgeModel(badgeModel, data);
        }

        // Check if the badge model was created
        uint256 newBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();
        assertTrue(newBadgeModelCount > initialBadgeModelCount, "Badge model should be created");

        // Retrieve the created badge model
        (
            address creator,
            string memory _controllerName,
            bool paused,
            uint256 _mintCreatorFee,
            uint256 _validFor,
            uint256 _mintProtocolFee,
            bool initialized,
            ,
            bool _suspended,
            ,

        ) = badgeStoreInstance.badgeModels(newBadgeModelCount - 1); // Assuming the last badge model was created

        // Perform assertions
        assertEq(creator, user1, "Creator should match");
        assertEq(paused, false, "Badge model should not be paused");
        assertEq(
            _mintProtocolFee,
            badgeStoreInstance.mintBadgeProtocolDefaultFeeInBps(),
            "Mint protocol fee should match"
        );
        assertTrue(initialized, "Badge model should be initialized");
        assertEq(controllerName, _controllerName, "Controller name should match");
        assertEq(mintCreatorFee, _mintCreatorFee, "Mint creator fee should match");
        assertEq(validFor, _validFor, "Valid for should match");
        assertEq(_suspended, false);

        // TODO: Assert creation event if needed
    }

    function testCreateThirdPartyBadgeModelOnTpController() public {
        // Register a user
        vm.prank(user1);
        badgeUsersInstance.registerUser("ipfs://creatorMetadata.json", false);

        // Register the user as third party one
        vm.prank(user1);
        badgeUsersInstance.submitUserVerification("thirdParty", "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsersInstance.executeUserVerification(user1, "thirdParty", true);

        // Create a badge model
        TheBadgeStore.CreateBadgeModel memory badgeModel = TheBadgeStore.CreateBadgeModel({
            metadata: "ipfs://badgeModelMetadata.json",
            controllerName: controllerName,
            mintCreatorFee: mintCreatorFee, // Adjust fee as needed
            validFor: validFor // Adjust validity period as needed
        });

        address[] memory administrators = new address[](1);
        administrators[0] = user1;
        TpBadgeModelControllerStore.CreateBadgeModel memory tpBadgeModel = TpBadgeModelControllerStore
            .CreateBadgeModel({ administrators: administrators });

        bytes memory data = abi.encode(tpBadgeModel);

        uint256 initialBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform the createBadgeModel transaction
        {
            vm.prank(user1);
            badgeModelsInstance.createBadgeModel(badgeModel, data);
        }

        // Check if the badge model was created
        uint256 newBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();
        uint256 currentTpBadgeModelId = tpBadgeModelControllerStoreInstance.getCurrentBadgeModelsIdCounter();
        assertTrue(newBadgeModelCount > initialBadgeModelCount, "Badge model should be created");

        // Retrieve the created badge model
        (
            address owner,
            uint256 badgeModelId,
            address tcrList,
            address tcrGovernor,
            address tcrAdmin
        ) = tpBadgeModelControllerStoreInstance.thirdPartyBadgeModels(newBadgeModelCount - 1); // Assuming the last badge model was created

        // Perform assertions over thirdPartyBadgeModel
        assertEq(owner, user1, "Owner should match");
        assertEq(badgeModelId, currentTpBadgeModelId - 1, "Tp badgeModelId and TheBadge badgeModelId should match");
        if (tcrList == address(0)) {
            revert("The tcrAdmin should not be empty");
        }
        assertEq(
            tcrGovernor,
            address(tpBadgeModelControllerInstance),
            "The governor should match the address of the tpBadgeModelController"
        );
        assertEq(
            tcrAdmin,
            address(tpBadgeModelControllerInstance),
            "The tcrAdmin should match the address of the tpBadgeModelController"
        );

        // Perform assertions over TCRList
        ILightGeneralizedTCR tcrListInstance = ILightGeneralizedTCR(tcrList);
        assertEq(
            tcrGovernor,
            address(tcrListInstance.governor()),
            "The tcrList should be created with the correct governor"
        );
        assertEq(
            tcrAdmin,
            address(tcrListInstance.relayerContract()),
            "The tcrList should be created with the correct admin"
        );
        // TODO: Assert creation event if needed
    }
}
