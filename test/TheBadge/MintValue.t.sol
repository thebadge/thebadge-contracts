// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Config } from "./Config.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { KlerosBadgeModelController } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { KlerosBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import { TpBadgeModelController } from "../../../src/contracts/badgeModelControllers/TpBadgeModelController.sol";
import { TpBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";

contract MintValue is Config {
    function testWorksKlerosWithoutMintCreatorFee() public {
        // register user
        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        uint256 mintCreatorFee = 0;
        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: klerosControllerName,
            mintCreatorFee: mintCreatorFee,
            validFor: 100
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

        // Creates the klerosBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, data);
        vm.stopPrank();

        uint256 badgeModelId = 0;

        vm.prank(u2);
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 klerosMintValue = klerosBadgeModelControllerInstance.mintValue(badgeModelId);

        // No extra fees than the kleros fee
        assertEq(mintValue, klerosMintValue);
    }

    function testWorkKlerossWithCreatorFee() public {
        // register user
        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        uint256 mintCreatorFee = 0.1e18;
        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: klerosControllerName,
            mintCreatorFee: mintCreatorFee,
            validFor: 100
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

        // Creates the klerosBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, data);
        vm.stopPrank();

        uint256 badgeModelId = 0;

        vm.prank(u2);
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 klerosMintValue = klerosBadgeModelControllerInstance.mintValue(badgeModelId);

        // Should be the klerosFee + the creatorFee + the claimFee
        assertEq(mintValue, klerosMintValue + mintCreatorFee);
    }

    function testWorkKlerossWithCreatorFeeAndClaimFee() public {
        // register user
        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        uint256 mintCreatorFee = 0.1e18;
        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: klerosControllerName,
            mintCreatorFee: mintCreatorFee,
            validFor: 100
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

        // Creates the klerosBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, data);
        vm.stopPrank();

        // Sets the claim fee
        uint256 claimProtocolFee = 0.0004e18;
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);

        uint256 badgeModelId = 0;
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 klerosMintValue = klerosBadgeModelControllerInstance.mintValue(badgeModelId);

        // Should be the klerosFee + the creatorFee + the claimFee
        assertEq(mintValue, klerosMintValue + mintCreatorFee + claimProtocolFee);
    }

    function testWorkThirdPartyWithoutCreatorFeeAndClaimFee() public {
        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // Register the user as third party one
        vm.prank(u1);
        badgeUsers.submitUserVerification(tpControllerName, "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsers.executeUserVerification(u1, tpControllerName, true);

        uint256 mintCreatorFee = 0;
        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: tpControllerName,
            mintCreatorFee: mintCreatorFee,
            validFor: 100
        });

        address[] memory administrators = new address[](1);
        administrators[0] = u1;
        TpBadgeModelControllerStore.CreateBadgeModel memory tpBadgeModel = TpBadgeModelControllerStore
            .CreateBadgeModel({
                administrators: administrators,
                requirementsIPFSHash: "ipfs://requirementsIPFSHash.json"
            });
        bytes memory data = abi.encode(tpBadgeModel);

        // Creates the tpBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, data);
        vm.stopPrank();

        // Sets the claim fee
        uint256 claimProtocolFee = 0;
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);

        uint256 badgeModelId = 0;
        uint256 mintValue = theBadge.mintValue(badgeModelId);

        // Should be the tpsMintValue + the creatorFee + the claimFee
        assertEq(mintValue, 0);
    }

    function testWorkThirdPartyWithCreatorFeeAndClaimFee() public {
        // register user
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // Register the user as third party one
        vm.prank(u1);
        badgeUsers.submitUserVerification(tpControllerName, "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsers.executeUserVerification(u1, tpControllerName, true);

        uint256 mintCreatorFee = 0.1e18;
        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: tpControllerName,
            mintCreatorFee: mintCreatorFee,
            validFor: 100
        });

        address[] memory administrators = new address[](1);
        administrators[0] = u1;
        TpBadgeModelControllerStore.CreateBadgeModel memory tpBadgeModel = TpBadgeModelControllerStore
            .CreateBadgeModel({
                administrators: administrators,
                requirementsIPFSHash: "ipfs://requirementsIPFSHash.json"
            });
        bytes memory data = abi.encode(tpBadgeModel);

        // Creates the tpBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, data);
        vm.stopPrank();

        // Sets the claim fee
        uint256 claimProtocolFee = 0.0004e18;
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);

        uint256 badgeModelId = 0;
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 tpsMintValue = 0;

        // Should be the tpsMintValue + the creatorFee + the claimFee
        assertEq(mintValue, tpsMintValue + mintCreatorFee + claimProtocolFee);
    }
}
