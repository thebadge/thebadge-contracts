// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { Config, TheBadge } from "./utils/Config.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ILightGeneralizedTCR } from "../src/interfaces/ILightGeneralizedTCR.sol";

contract TheBadgeTestSoulbound is Config {
    function test_setApprovalForAll_shouldRevert() public {
        vm.prank(admin);
        vm.expectRevert(TheBadge.TheBadge__ERC1155_notAllowed.selector);
        theBadge.setApprovalForAll(address(0), true);
    }

    function test_safeTransferFrom_shouldRevert() public {
        vm.prank(admin);
        vm.expectRevert(TheBadge.TheBadge__ERC1155_notAllowed.selector);
        theBadge.safeTransferFrom(address(0), address(0), 1, 1, "0x");
    }

    function test_safeBatchTransferFrom_shouldRevert() public {
        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        vm.prank(admin);
        vm.expectRevert(TheBadge.TheBadge__ERC1155_notAllowed.selector);
        theBadge.safeBatchTransferFrom(address(0), address(0), ids, amounts, "0x");
    }
}
