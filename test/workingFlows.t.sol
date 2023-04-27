// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

// import { AddressUpgradeable } from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";
import { Config, TheBadge, TheBadgeLogic, KlerosController } from "./utils/Config.sol";

contract TheBadgeTestCore is Config {
    function test_createKlerosBadgeType_shouldWork() public {
        // register creator
        vm.prank(vegeta);
        theBadge.registerBadgeTypeCreator("ipfs://creatorMetadata.json");

        // Crete badge type
        vm.prank(vegeta);
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));

        (
            address emitter,
            string memory controllerName,
            bool paused,
            uint256 mintCreatorFee,
            uint256 validFor,
            uint256 mintProtocolFee
        ) = theBadge.badgeType(0);

        address tcrList = klerosController.klerosBadgeType(0);

        assertEq(vegeta, emitter);
        assertEq(controllerName, badgeType.controllerName);
        assertEq(paused, false);
        assertEq(mintCreatorFee, badgeType.mintCreatorFee);
        assertEq(validFor, badgeType.validFor);
        assertEq(mintProtocolFee, theBadge.mintBadgeDefaultFee());
        assertFalse(tcrList == address(0));
    }

    function test_mintKlerosBadge_shouldWork() public {
        // register creator
        vm.prank(vegeta);
        theBadge.registerBadgeTypeCreator("ipfs://creatorMetadata.json");

        // Crete badge type
        vm.prank(vegeta);
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));

        // first badgeType has id = 0;
        uint256 badgeTypeId = 0;

        // check goku account has not balance for badgeTypeId
        assertEq(theBadge.balanceOfBadgeType(goku, badgeTypeId), 0);

        // goku mints badgeTypeId
        uint256 mintValue = theBadge.mintValue(badgeTypeId);
        string memory evidenceUri = "ipfs://evidence.json";
        KlerosController.MintParams memory badgeInfo = KlerosController.MintParams(evidenceUri);
        vm.prank(goku);
        theBadge.mint{ value: mintValue }(badgeTypeId, goku, evidenceUri, abi.encode(badgeInfo));

        // first badge has id = 0;
        uint256 badgeId = 0;

        // check goku account has not balance for badgeTypeId.
        // at this moment, the badge is in review period, so balance has to be still 0.
        assertEq(theBadge.balanceOfBadgeType(goku, badgeTypeId), 0);

        // check status on KlerosController
        (bytes32 itemID, address mintCallee, uint256 deposit) = klerosController.klerosBadge(badgeId);
        assertEq(itemID, keccak256(abi.encodePacked(evidenceUri)));
        assertEq(mintCallee, goku);
        assertEq(deposit, mintValue - badgeType.mintCreatorFee);
        assertEq(theBadge.balanceOf(goku, badgeId), 0); // balanceOf is 0 until challenge period ends and claimKlerosBadge is called

        // move timestamp 1 unit after the challenge period has due.
        address tcrList = klerosController.klerosBadgeType(badgeTypeId);
        uint256 challengePeriodDuration = ILightGeneralizedTCR(tcrList).challengePeriodDuration();
        vm.warp(block.timestamp + challengePeriodDuration + 1);

        // claim badge
        uint256 prevBalance = goku.balance;
        klerosController.claim(badgeId);
        assertEq(goku.balance, prevBalance + deposit);
        assertEq(theBadge.balanceOfBadgeType(goku, badgeTypeId), 1);
    }
}
