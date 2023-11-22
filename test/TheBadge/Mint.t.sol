// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Config } from "./Config.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";

contract Mint is Config {
    function testWorks() public {
        vm.startPrank(admin);
        badgeStore.addPermittedContract("TheBadge", address(badge));
        vm.stopPrank();
        
        address controllerAddress = vm.addr(11);
        vm.deal(controllerAddress, 10 ether);
        string memory controllerName = "controllerName";

        TheBadgeStore.BadgeModelController memory _badgeModelController = TheBadgeStore.BadgeModelController({
            controller: controllerAddress,
            initialized: true,
            paused: false
        });

        uint256 mintCreatorFee = 0.1e18;

        vm.startPrank(address(badge));
        badgeStore.addBadgeModelController(controllerName, _badgeModelController);
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(
                u1,
                controllerName,
                false,
                mintCreatorFee,
                100,
                1000,
                true,
                1,
                false,
                false,
                "metadata"
            )
        );
        vm.stopPrank();

        uint256 badgeModelId = 0;
        string memory tokenURI = "ipfs://metadata";
        bytes memory data = "blabla";

        uint256 controllerMintValue = 0.2e18;

        vm.mockCall(
            controllerAddress,
            abi.encodeWithSelector(IBadgeModelController.mintValue.selector, badgeModelId),
            abi.encode(controllerMintValue)
        );

        vm.deal(address(badge), 10 ether);

        vm.mockCall(
            controllerAddress,
            abi.encodeWithSelector(IBadgeModelController.mint.selector),
            abi.encode(1)
        );

        vm.prank(u2);
        badge.mint{ value: (controllerMintValue + mintCreatorFee) }(badgeModelId, u1, tokenURI, data);
    }
}
