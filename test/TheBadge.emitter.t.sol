// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { Config, TheBadge } from "./utils/Config.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";

contract TheBadgeTestEmitter is Config {
    function test_registerEmitter_alreadyRegistered() public {
        string memory ipfsUrl = "ipfs://";
        string memory ipfsUrl2 = "ipfs://2";
        address emitter = address(1);

        vm.prank(vegeta);
        theBadge.registerEmitter(emitter, ipfsUrl);

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__registerEmitter_alreadyRegistered.selector);
        theBadge.registerEmitter(emitter, ipfsUrl2);
    }

    function test_registerEmitter_invalidAddress() public {
        string memory _ipfsUrl = "ipfs://";

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__registerEmitter_invalidAddress.selector);
        theBadge.registerEmitter(address(0), _ipfsUrl);
    }

    function test_registerEmitter_wrongValue() public {
        string memory _ipfsUrl = "ipfs://";

        vm.prank(admin);
        theBadge.updateValues(0, 0, 0, 1);

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__registerEmitter_wrongValue.selector);
        theBadge.registerEmitter(vegeta, _ipfsUrl);
    }

    function test_registerEmitter_shouldWork() public {
        string memory _ipfsUrl = "ipfs://";

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, _ipfsUrl);

        string memory metadata = theBadge.emitters(address(vegeta));

        assertEq(_ipfsUrl, metadata);
    }

    function test_updateEmitter_notAdmin() public {
        string memory _ipfsUrl = "ipfs://";

        vm.prank(vegeta);
        theBadge.registerEmitter(vegeta, _ipfsUrl);

        vm.prank(vegeta);
        vm.expectRevert(TheBadge.TheBadge__onlyAdmin_senderIsNotAdmin.selector);
        theBadge.updateEmitter(vegeta, "");
    }

    function test_updateEmitter_notFound() public {
        string memory _ipfsUrl = "ipfs://";

        vm.prank(admin);
        vm.expectRevert(TheBadge.TheBadge__updateEmitter_notFound.selector);
        theBadge.updateEmitter(address(100), _ipfsUrl);
    }

    function test_updateEmitter_shouldWork() public {
        string memory ipfsUrl1 = "ipfs://";
        string memory ipfsUrl2 = "ipfs2://";

        vm.prank(admin);
        theBadge.registerEmitter(vegeta, ipfsUrl1);

        vm.prank(admin);
        theBadge.updateEmitter(vegeta, ipfsUrl2);

        string memory metadata = theBadge.emitters(vegeta);
        assertEq(metadata, ipfsUrl2);
    }
}
