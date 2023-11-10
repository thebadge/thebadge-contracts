pragma solidity ^0.8.20;

import { TheBadgeModels } from "../../../src/contracts/thebadge/TheBadgeModels.sol"; // Use the appropriate Solidity version
import { TheBadgeStore } from "../../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../../../src/contracts/thebadge/TheBadgeUsers.sol";
import { KlerosBadgeModelController } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { KlerosBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import { ILightGeneralizedTCR } from "../../../src/interfaces/ILightGeneralizedTCR.sol";
import { Config } from "./Config.sol";
import "forge-std/console.sol";

contract CreateBadgeModel is Config {
    function testCreateKlerosBadgeModel() public {
        // Register a user
        vm.prank(user1);
        badgeUsersInstance.registerUser("ipfs://creatorMetadata.json", false);

        // Create a badge model
        TheBadgeStore.CreateBadgeModel memory badgeModel = TheBadgeStore.CreateBadgeModel({
            metadata: "ipfs://badgeModelMetadata.json",
            controllerName: "kleros",
            mintCreatorFee: 100, // Adjust fee as needed
            validFor: 365 days // Adjust validity period as needed
        });

        uint256[4] memory baseDeposits = [uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256[3] memory stakeMultipliers = [uint256(1), uint256(1), uint256(1)];
        KlerosBadgeModelControllerStore.CreateBadgeModel memory klerosBadgeModel = KlerosBadgeModelControllerStore
            .CreateBadgeModel({
                governor: vm.addr(1),
                courtId: 0,
                numberOfJurors: 1,
                registrationMetaEvidence: "ipfs://registrationMetaEvidence.json",
                clearingMetaEvidence: "ipfs://clearingMetaEvidence.json",
                challengePeriodDuration: 0,
                baseDeposits: baseDeposits,
                stakeMultipliers: stakeMultipliers
            });
        TheBadgeStore.CreateBadgeModel memory _badgeModel = badgeModel;

        bytes memory data = abi.encode(klerosBadgeModel);

        uint256 initialBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform the createBadgeModel transaction
        vm.prank(user1);
        badgeModelsInstance.createBadgeModel(badgeModel, data);

        // Check if the badge model was created
        uint256 newBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();
        assertTrue(newBadgeModelCount > initialBadgeModelCount, "Badge model should be created");

        // Retrieve the created badge model
        (
            address creator,
            string memory _controllerName,
            bool paused,
            uint256 mintCreatorFee,
            uint256 validFor,
            uint256 mintProtocolFee,
            bool initialized,
            ,
            bool _suspended,
            ,

        ) = badgeStoreInstance.badgeModels(newBadgeModelCount - 1); // Assuming the last badge model was created

        // Perform assertions
        assertEq(creator, user1, "Creator should match");
        assertEq(_controllerName, _badgeModel.controllerName, "Controller name should match");
        assertEq(paused, false, "Badge model should not be paused");
        assertEq(mintCreatorFee, _badgeModel.mintCreatorFee, "Mint creator fee should match");
        assertEq(validFor, _badgeModel.validFor, "Valid for should match");
        assertEq(
            mintProtocolFee,
            badgeStoreInstance.mintBadgeProtocolDefaultFeeInBps(),
            "Mint protocol fee should match"
        );
        assertTrue(initialized, "Badge model should be initialized");
        assertEq(_suspended, false);

        // TODO: Assert creation event if needed
    }

    function testCreateKlerosBadgeModelOnKlerosController() public {
        // Register a user
        vm.prank(user1);
        badgeUsersInstance.registerUser("ipfs://creatorMetadata.json", false);

        // Create a badge model
        TheBadgeStore.CreateBadgeModel memory badgeModel = TheBadgeStore.CreateBadgeModel({
            metadata: "ipfs://badgeModelMetadata.json",
            controllerName: "kleros",
            mintCreatorFee: 100, // Adjust fee as needed
            validFor: 365 days // Adjust validity period as needed
        });

        uint256[4] memory baseDeposits = [uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256[3] memory stakeMultipliers = [uint256(1), uint256(1), uint256(1)];
        KlerosBadgeModelControllerStore.CreateBadgeModel memory klerosBadgeModel = KlerosBadgeModelControllerStore
            .CreateBadgeModel({
                governor: vm.addr(1),
                courtId: 0,
                numberOfJurors: 1,
                registrationMetaEvidence: "ipfs://registrationMetaEvidence.json",
                clearingMetaEvidence: "ipfs://clearingMetaEvidence.json",
                challengePeriodDuration: 0,
                baseDeposits: baseDeposits,
                stakeMultipliers: stakeMultipliers
            });

        bytes memory data = abi.encode(klerosBadgeModel);

        uint256 initialBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform the createBadgeModel transaction
        vm.prank(user1);
        badgeModelsInstance.createBadgeModel(badgeModel, data);

        // Check if the badge model was created
        uint256 newBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();
        assertTrue(newBadgeModelCount > initialBadgeModelCount, "Badge model should be created");
        uint256 newBadgeModelId = newBadgeModelCount - 1;

        // Retrieve the created klerosBadgeModel
        (
            address owner,
            uint256 klerosBadgeModelId,
            address tcrList,
            address tcrGovernor,
            address tcrAdmin,
            bool klerosModelInitialized
        ) = klerosBadgeModelControllerStoreInstance.klerosBadgeModels(newBadgeModelId);

        uint256 currentKlerosBadgeModelId = klerosBadgeModelControllerStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform assertions over klerosBadgeModel
        assertEq(owner, user1, "Owner should match");
        assertEq(klerosBadgeModelId, newBadgeModelId, "Kleros badgeModelId and TheBadge badgeModelId should match");
        assertEq(
            currentKlerosBadgeModelId - 1,
            newBadgeModelId,
            "Kleros badgeModelId and TheBadge badgeModelId should match"
        );
        if (tcrList == address(0)) {
            revert("The tcrAdmin should not be empty");
        }
        assertEq(klerosBadgeModel.governor, tcrGovernor, "The governor and the badgeModel owner should match");
        assertEq(tcrAdmin, address(0), "The tcrAdmin should match ZERO_ADDRESS");
        assertTrue(klerosModelInitialized, "KlerosBadgeModel should be initialized");

        // Perform assertions over TCRList
        address arbitrator = address(klerosBadgeModelControllerStoreInstance.arbitrator());
        ILightGeneralizedTCR tcrListInstance = ILightGeneralizedTCR(tcrList);
        assertEq(
            arbitrator,
            address(tcrListInstance.arbitrator()),
            "The tcrList should be created with the correct arbitrator"
        );
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
