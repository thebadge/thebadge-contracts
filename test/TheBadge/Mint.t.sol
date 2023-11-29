// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Config } from "./Config.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { KlerosBadgeModelController } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { KlerosBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import { TpBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";
import { TpBadgeModelController } from "../../src/contracts/badgeModelControllers/TpBadgeModelController.sol";

contract Mint is Config {
    function klerosBadgeModelSetup(uint256 mintCreatorFee) public {
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
        bytes memory createBadgeModelData = abi.encode(klerosBadgeModel);

        // Creates the klerosBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, createBadgeModelData);
        vm.stopPrank();
    }

    function thirdPartyBadgeModelSetup(uint256 mintCreatorFee) public {
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
        bytes memory createBadgeModelData = abi.encode(tpBadgeModel);

        // Creates the tpBadgeModel
        vm.startPrank(u1);
        badgeModels.createBadgeModel{ value: 0 }(args, createBadgeModelData);
        vm.stopPrank();
    }

    function testWorksWithKleros() public {
        // register user
        // U1 is the creator; U2 is the minter
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        uint256 claimProtocolFee = 0.0004e18;

        // Setups the claim protocol fee
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);
        klerosBadgeModelSetup(0.1e18);

        KlerosBadgeModelControllerStore.MintParams memory mintKlerosData = KlerosBadgeModelControllerStore.MintParams({
            evidence: "ipfs://evidence"
        });

        uint256 badgeModelId = 0;
        string memory tokenURI = "ipfs://metadata";
        bytes memory mintData = abi.encode(mintKlerosData);

        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 mintProtocolFeeInBps = badgeStore.mintBadgeProtocolDefaultFeeInBps();
        uint256 userCreatorInitialBalance = address(u1).balance;
        uint256 feeCollectorInitialBalance = address(feeCollector).balance;
        uint256 mintCreatorFee = 0.1e18;

        // Ensures that the controller fee is well calculated
        uint256 controllerMintValue = klerosBadgeModelControllerInstance.mintValue(badgeModelId);
        assertEq(mintValue, controllerMintValue + mintCreatorFee + claimProtocolFee);

        vm.prank(u2);
        // Executes the mint
        theBadge.mint{ value: mintValue }(badgeModelId, u1, tokenURI, mintData);

        uint256 userCreatorFinalBalance = address(u1).balance;
        uint256 feeCollectorFinalBalance = address(feeCollector).balance;

        // Ensures that the creator receives his payment
        assertEq(
            userCreatorFinalBalance,
            userCreatorInitialBalance + (mintCreatorFee - (mintCreatorFee * mintProtocolFeeInBps) / 10_000)
        );
        // Ensures that the TheBadge's fee collector receives his payment
        assertEq(
            feeCollectorFinalBalance,
            feeCollectorInitialBalance + ((mintCreatorFee * mintProtocolFeeInBps) / 10_000) + claimProtocolFee
        );

        uint256 theBadgeBalance = address(theBadge).balance;
        // Ensures that theBadgeBalance is 0
        assertEq(theBadgeBalance, 0);

        // Ensures that the klerosController balance is 0
        uint256 klerosControllerBalance = address(klerosBadgeModelControllerInstance).balance;
        assertEq(klerosControllerBalance, 0);

        // Ensures that the kleros deposit is stored on the tcr
        KlerosBadgeModelControllerStore.KlerosBadgeModel
            memory _klerosBadgeModel = klerosBadgeModelControllerStoreInstance.getKlerosBadgeModel(badgeModelId);
        uint256 tcrBalance = address(_klerosBadgeModel.tcrList).balance;
        assertEq(tcrBalance, controllerMintValue);
    }

    function testWorksWithThirdPartyWithRecipient() public {
        // register user
        // U1 is the creator; U2 is the minter
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // Register the user as third party one
        vm.prank(u1);
        badgeUsers.submitUserVerification(tpControllerName, "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsers.executeUserVerification(u1, tpControllerName, true);

        uint256 claimProtocolFee = 0.0004e18;

        // Setups the claim protocol fee
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);
        thirdPartyBadgeModelSetup(0.1e18);

        TpBadgeModelControllerStore.MintParams memory mintThirdPartyData = TpBadgeModelControllerStore.MintParams({
            badgeDataUri: "ipfs://evidence"
        });

        uint256 badgeModelId = 0;
        string memory tokenURI = "ipfs://metadata";
        bytes memory mintData = abi.encode(mintThirdPartyData);
        uint256 mintCreatorFee = 0.1e18;
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 mintProtocolFeeInBps = badgeStore.mintBadgeProtocolDefaultFeeInBps();
        uint256 userCreatorInitialBalance = address(u1).balance;
        uint256 feeCollectorInitialBalance = address(feeCollector).balance;

        // Ensures that the controller fee is well calculated
        uint256 controllerMintValue = tpBadgeModelControllerInstance.mintValue(badgeModelId);
        assertEq(mintValue, controllerMintValue + mintCreatorFee + claimProtocolFee);

        // Executes the mint and sends the badge to the user2
        vm.prank(u1);
        theBadge.mint{ value: mintValue }(badgeModelId, u2, tokenURI, mintData);

        uint256 userCreatorFinalBalance = address(u1).balance;
        uint256 feeCollectorFinalBalance = address(feeCollector).balance;

        // Ensures that the TheBadge's fee collector receives his payment
        uint256 theBadgeFees = (mintCreatorFee * mintProtocolFeeInBps) / 10_000;
        assertEq(feeCollectorFinalBalance, feeCollectorInitialBalance + theBadgeFees + claimProtocolFee);

        // Ensures that the tp creator had made his payment
        assertEq(userCreatorFinalBalance, userCreatorInitialBalance - theBadgeFees - claimProtocolFee);

        // Ensures that theBadgeBalance is 0
        assertEq(address(theBadge).balance, 0);

        // Ensures that the thirdPartyController balance is 0
        assertEq(address(tpBadgeModelControllerInstance).balance, 0);

        // Ensures that the's no deposit stored on the tp tcr
        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _tpBadgeModel = tpBadgeModelControllerStoreInstance
            .getBadgeModel(badgeModelId);
        uint256 tcrBalance = address(_tpBadgeModel.tcrList).balance;
        assertEq(tcrBalance, 0);

        // Ensures that the recipient has his badge
        uint256 badgeId = badgeStore.getCurrentBadgeIdCounter() - 1;
        assertGt(theBadge.balanceOf(u2, badgeId), 0);

        // Ensures that the badge is not claimable
        assertFalse(theBadge.isClaimable(badgeId));

        // Ensures that the badge is not expired
        assertFalse(theBadge.isExpired(badgeId));

        // Ensures that the badgeModel for the user now contains 1 badge minted
        assertEq(theBadge.balanceOfBadgeModel(u2, 0), 1);
    }

    function testWorksWithThirdPartyWithoutRecipient() public {
        // register user
        // U1 is the creator; U2 is the minter
        vm.prank(u1);
        badgeUsers.registerUser("user metadata", false);

        // Register the user as third party one
        vm.prank(u1);
        badgeUsers.submitUserVerification(tpControllerName, "ipfs://evidenceMetadata.json");

        // Verify the user to be a third party user
        vm.prank(admin);
        badgeUsers.executeUserVerification(u1, tpControllerName, true);

        uint256 claimProtocolFee = 0.0004e18;

        // Setups the claim protocol fee
        vm.prank(admin);
        theBadge.updateClaimBadgeProtocolFee(claimProtocolFee);
        thirdPartyBadgeModelSetup(0.1e18);

        TpBadgeModelControllerStore.MintParams memory mintThirdPartyData = TpBadgeModelControllerStore.MintParams({
            badgeDataUri: "ipfs://evidence"
        });

        uint256 badgeModelId = 0;
        string memory tokenURI = "ipfs://metadata";
        bytes memory mintData = abi.encode(mintThirdPartyData);
        uint256 mintCreatorFee = 0.1e18;
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        uint256 mintProtocolFeeInBps = badgeStore.mintBadgeProtocolDefaultFeeInBps();
        uint256 userCreatorInitialBalance = address(u1).balance;
        uint256 feeCollectorInitialBalance = address(feeCollector).balance;

        // Ensures that the controller fee is well calculated
        uint256 controllerMintValue = tpBadgeModelControllerInstance.mintValue(badgeModelId);
        assertEq(mintValue, controllerMintValue + mintCreatorFee + claimProtocolFee);

        // Executes the mint and sends the badge to undefined recipient
        vm.prank(u1);
        theBadge.mint{ value: mintValue }(badgeModelId, address(0), tokenURI, mintData);

        uint256 userCreatorFinalBalance = address(u1).balance;
        uint256 feeCollectorFinalBalance = address(feeCollector).balance;

        // Ensures that the TheBadge's fee collector receives his payment
        uint256 theBadgeFees = (mintCreatorFee * mintProtocolFeeInBps) / 10_000;
        assertEq(feeCollectorFinalBalance, feeCollectorInitialBalance + theBadgeFees + claimProtocolFee);

        // Ensures that the tp creator had made his payment
        assertEq(userCreatorFinalBalance, userCreatorInitialBalance - theBadgeFees - claimProtocolFee);

        // Ensures that theBadgeBalance is 0
        assertEq(address(theBadge).balance, 0);

        // Ensures that the thirdPartyController balance is 0
        assertEq(address(tpBadgeModelControllerInstance).balance, 0);

        // Ensures that the's no deposit stored on the tp tcr
        TpBadgeModelControllerStore.ThirdPartyBadgeModel memory _tpBadgeModel = tpBadgeModelControllerStoreInstance
            .getBadgeModel(badgeModelId);
        uint256 tcrBalance = address(_tpBadgeModel.tcrList).balance;
        assertEq(tcrBalance, 0);

        // Ensures that the badge is stored on the tpBadgeModelControllerInstance
        uint256 badgeId = badgeStore.getCurrentBadgeIdCounter() - 1;
        assertGt(theBadge.balanceOf(address(tpBadgeModelControllerInstance), badgeId), 0);

        // Ensures that the badge is claimable
        assertTrue(theBadge.isClaimable(badgeId));

        // Ensures that the badge is not expired
        assertFalse(theBadge.isExpired(badgeId));

        // Ensures that the badgeModel for the badgeModel user now contains 1 badge minted
        assertEq(theBadge.balanceOfBadgeModel(address(tpBadgeModelControllerInstance), 0), 1);
    }
}
