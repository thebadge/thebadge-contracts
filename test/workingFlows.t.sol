// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { ILightGeneralizedTCR } from "../src/interfaces/facets/ILightGeneralizedTCR.sol";
import { Config, TheBadge, TheBadgeStore, KlerosBadgeModelController, KlerosBadgeModelControllerStore } from "./utils/Config.sol";

contract TheBadgeTestCore is Config {
    function test_createKlerosBadgeModel_shouldWork() public {
        // register User
        vm.prank(vegeta);
        theBadge.registerUser("ipfs://creatorMetadata.json", false);

        // Create badge model
        vm.prank(vegeta);
        TheBadge.CreateBadgeModel memory badgeModel = getBaseBadgeModel();
        KlerosBadgeModelController.CreateBadgeModel memory klerosBadgeModel = getKlerosBaseBadgeModel();
        theBadge.createBadgeModel(badgeModel, abi.encode(klerosBadgeModel));

        (
            address creator,
            string memory controllerName,
            bool paused,
            uint256 mintCreatorFee,
            uint256 validFor,
            uint256 mintProtocolFee,
            bool initialized,

        ) = theBadge.badgeModels(0);

        address tcrList = klerosBadgeModelController.klerosBadgeModels(0);

        assertEq(vegeta, creator);
        assertEq(controllerName, badgeModel.controllerName);
        assertEq(paused, false);
        assertEq(mintCreatorFee, badgeModel.mintCreatorFee);
        assertEq(validFor, badgeModel.validFor);
        assertEq(mintProtocolFee, theBadge.mintBadgeProtocolDefaultFeeInBps());
        assertFalse(tcrList == address(0));
        assertTrue(initialized);
        // TODO assert creation event
    }

    function test_mintKlerosBadge_shouldWork() public {
        // register user
        vm.prank(vegeta);
        theBadge.registerUser("ipfs://creatorMetadata.json", false);

        // Create badge model
        vm.prank(vegeta);
        TheBadge.CreateBadgeModel memory badgeModel = getBaseBadgeModel();
        KlerosBadgeModelController.CreateBadgeModel memory klerosBadgeModel = getKlerosBaseBadgeModel();
        theBadge.createBadgeModel(badgeModel, abi.encode(klerosBadgeModel));

        // first  id = 0;
        uint256 badgeModelId = 0;

        // check goku account has not balance for badgeModelId
        assertEq(theBadge.balanceOfBadgeModel(goku, badgeModelId), 0);

        // goku mints badgeModelId
        uint256 mintValue = theBadge.mintValue(badgeModelId);
        string memory evidenceUri = "ipfs://evidence.json";
        KlerosBadgeModelController.MintParams memory badgeInfo = KlerosBadgeModelControllerStore.MintParams(
            evidenceUri
        );
        vm.prank(goku);
        theBadge.mint{ value: mintValue }(badgeModelId, goku, evidenceUri, abi.encode(badgeInfo));

        // first badge has id = 0;
        uint256 badgeId = 0;

        // check goku account has not balance for badgeModelId.
        // at this moment, the badge is in review period, so balance has to be still 0.
        assertEq(theBadge.balanceOfBadgeModel(goku, badgeModelId), 0);
        // check status on KlerosBadgeModelController
        (bytes32 itemID, address mintCallee, uint256 deposit, ) = klerosBadgeModelController.klerosBadges(badgeId);
        assertEq(itemID, keccak256(abi.encodePacked(evidenceUri)));
        assertEq(mintCallee, goku);
        assertEq(deposit, mintValue - badgeModel.mintCreatorFee);
        assertEq(theBadge.balanceOf(goku, badgeId), 0); // balanceOf is 0 until challenge period ends and claimKlerosBadge is called

        // move timestamp 1 unit after the challenge period has due.
        address tcrList = klerosBadgeModelController.klerosBadgeModels(badgeModelId);
        uint256 challengePeriodDuration = ILightGeneralizedTCR(tcrList).challengePeriodDuration();
        vm.warp(block.timestamp + challengePeriodDuration + 1);
        // claim badge
        uint256 prevBalance = goku.balance;
        // Changes the sender to TheBadge to be able to pass the modify onlyTheBadge
        vm.prank(address(klerosBadgeModelController.theBadge()));
        klerosBadgeModelController.claim(badgeId, "0x");
        assertEq(goku.balance, prevBalance + deposit);
        assertEq(theBadge.balanceOfBadgeModel(goku, badgeModelId), 1);
    }
}
