// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "@openzeppelin/contracts/utils/StringsUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts/utils/AddressUpgradeable.sol";

import { Config, TheBadge, KlerosBadgeTypeController, BadgeStatus } from "./utils/Config.sol";
import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";
import "../src/interfaces/IBadgeController.sol";

contract TheBadgeTest is Config {
    function getKlerosBaseBadgeType() public view returns (KlerosBadgeTypeController.CreateBadgeType memory) {
        uint256[4] memory baseDeposits;
        baseDeposits[0] = 1;
        baseDeposits[1] = 1;
        baseDeposits[2] = 1;
        baseDeposits[3] = 1;

        uint256[3] memory stakeMultipliers;
        stakeMultipliers[0] = 1;
        stakeMultipliers[1] = 1;
        stakeMultipliers[2] = 1;

        KlerosBadgeTypeController.CreateBadgeType memory strategy = KlerosBadgeTypeController.CreateBadgeType(
            address(0), // governor
            address(0), // admin
            1, // court
            1, // jurors
            "ipfs/registrationMetaEvidence.json",
            "ipfs/clearingMetaEvidence.json",
            1, // challengePeriodDuration
            baseDeposits,
            stakeMultipliers
        );
        return strategy;
    }

    function test_createKlerosBadgeType_shouldWork() public {
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosBadgeTypeController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        klerosBadgeType.challengePeriodDuration = 777;
        uint256 createdBadgeId = theBadge.badgeIds() + 1;

        vm.prank(vegeta);
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));

        (, string memory controllerName, , , , ) = theBadge.badgeType(createdBadgeId);
        assertEq(controllerName, "kleros");

        address tcrList = klerosController.klerosBadgeType(createdBadgeId);
        assertFalse(tcrList == address(0));
        uint256 challengeDuration = ILightGeneralizedTCR(tcrList).challengePeriodDuration();
        assertEq(challengeDuration, 777);
    }

    function test_mintKlerosBadge_shouldWork() public {
        // register emitter
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        // create badge-type
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosBadgeTypeController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        klerosBadgeType.mintCost = 1 ether;
        klerosBadgeType.challengePeriodDuration = 10;
        klerosBadgeType.validFor = 100;
        vm.prank(vegeta);
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));
        uint256 badgeId = theBadge.badgeIds();

        // create badge
        uint256 mintValue = theBadge.badgeRequestValue(badgeId);
        string memory evidence = "ipfs://evidence.json";
        KlerosBadgeTypeController.RequestBadgeData memory badgeInfo = KlerosBadgeTypeController.RequestBadgeData(
            evidence
        );
        vm.prank(goku);
        theBadge.requestBadge{ value: mintValue }(badgeId, goku, abi.encode(badgeInfo));

        (bytes32 itemID, address mintCallee, uint256 deposit) = klerosController.klerosBadge(badgeId, goku);

        // badge
        assertEq(itemID, keccak256(abi.encodePacked(evidence)));
        assertEq(mintCallee, goku);
        assertEq(deposit, mintValue - badgeType.mintCost);
        assertEq(theBadge.balanceOf(goku, badgeId), 0); // balanceOf is 0 until challenge period ends and claimKlerosBadge is called
    }

    function test_claimKlerosBadge_shouldWork() public {
        // register emitter
        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, "metadata");

        // create badge-type
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosBadgeTypeController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        klerosBadgeType.mintCost = 1 ether;
        klerosBadgeType.challengePeriodDuration = 10;
        klerosBadgeType.validFor = 100;
        vm.prank(vegeta);
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));
        uint256 badgeId = theBadge.badgeIds();

        // create badge
        uint256 mintValue = theBadge.badgeRequestValue(badgeId);
        string memory evidence = "ipfs://evidence.json";
        KlerosBadgeTypeController.RequestBadgeData memory badgeInfo = KlerosBadgeTypeController.RequestBadgeData(
            evidence
        );
        vm.prank(goku);
        theBadge.requestBadge{ value: mintValue }(badgeId, goku, abi.encode(badgeInfo));

        // claim badge
        uint256 prevBalance = goku.balance;
        (, , uint256 prevDeposit) = klerosController.klerosBadge(badgeId, goku);

        vm.warp(101);
        vm.prank(goku);
        klerosController.claimBadge(badgeId, goku);

        (BadgeStatus status, ) = theBadge.badge(badgeId, goku);
        (, , uint256 deposit) = klerosController.klerosBadge(badgeId, goku);

        assertEq(deposit, 0);
        assertEq(goku.balance, prevBalance + prevDeposit);
        assertEq(theBadge.balanceOf(goku, badgeId), 1);
        assertEq(uint8(BadgeStatus.Approved), uint8(status));
    }

    // function test_balanceOfDueBadge_shouldBeZero() public {
    //     // register emitter
    //     vm.prank(admin);
    //     theBadge.registerEmitter(vegeta, "ipfs://profile.json");

    //     // create strategy
    //     TheBadge.CreateKlerosBadgeType memory strategy = getKlerosBaseStrategy();
    //     strategy.mintCost = 0.05 ether;
    //     strategy.validFor = 100;
    //     vm.prank(vegeta);
    //     uint256 badgeTypeId = theBadge.createKlerosBadgeType(strategy);

    //     // claim badge

    //     vm.warp(500);
    //     uint256 balance = theBadge.balanceOf(goku, badgeTypeId);

    //     assertEq(balance, 0);
    // }

    // function test_balanceOfBeforeClaim_shouldBeZero() public {
    //     // register emitter
    //     vm.prank(admin);
    //     theBadge.registerEmitter(vegeta, "ipfs://profile.json");

    //     // create strategy
    //     TheBadge.CreateKlerosBadgeType memory strategy = getKlerosBaseStrategy();
    //     strategy.mintCost = 0.05 ether;
    //     strategy.validFor = 100;
    //     vm.warp(500);
    //     vm.prank(vegeta);
    //     uint256 badgeTypeId = theBadge.createKlerosBadgeType(strategy);

    //     // create badge
    //     (, , , uint256 mintCost, uint256 mintFee, ) = theBadge.badgeType(badgeTypeId);
    //     address createdStrategyAddress = theBadge.klerosBadgeType(badgeTypeId);

    //     uint256 mintValue = theBadge.getKlerosMintCost(badgeTypeId);
    //     vm.prank(goku);
    //     theBadge.mintBadgeFromKlerosStrategy{ value: mintValue }(badgeTypeId, "ipfs://evidence.json", goku);

    //     vm.warp(5000);

    //     uint256 balance = theBadge.balanceOf(goku, badgeTypeId);

    //     assertEq(balance, 0);
    // }
}
