// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

// import { AddressUpgradeable } from "../lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
// import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";

import { Config, TheBadge, TheBadgeLogic, KlerosBadgeTypeController } from "./utils/Config.sol";

contract TheBadgeTestCore is Config {
    function test_createKlerosBadgeType_shouldWork() public {
        // register creator
        vm.prank(vegeta);
        theBadge.registerBadgeTypeCreator("ipfs://creatorMetadata.json");

        // Crete badge type
        vm.prank(vegeta);
        TheBadge.CreateBadgeType memory badgeType = getBaseBadgeType();
        KlerosBadgeTypeController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
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
        KlerosBadgeTypeController.CreateBadgeType memory klerosBadgeType = getKlerosBaseBadgeType();
        theBadge.createBadgeType(badgeType, abi.encode(klerosBadgeType));

        address tcrList = klerosController.klerosBadgeType(0);
    }
}
