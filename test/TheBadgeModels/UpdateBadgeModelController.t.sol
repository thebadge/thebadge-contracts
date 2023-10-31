pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { Config } from "./Config.sol";

contract UpdateBadgeModelController is Config {
    event BadgeModelControllerUpdated(string indexed controllerName, address indexed controllerAddress);

    function testWorks() public {
        string memory controllerName = "controllerName";
        address controllerAddress = vm.addr(10);

        vm.expectEmit(true, true, false, true);
        emit BadgeModelControllerUpdated(controllerName, controllerAddress);

        TheBadgeStore.BadgeModelController memory _badgeModelController = TheBadgeStore.BadgeModelController({
            controller: controllerAddress,
            initialized: true,
            paused: false
        });

        vm.mockCall(
            address(badgeStore),
            abi.encodeWithSelector(TheBadgeStore.updateBadgeModelController.selector),
            abi.encode()
        );

        vm.expectCall(
            address(badgeStore),
            abi.encodeWithSelector(
                TheBadgeStore.updateBadgeModelController.selector,
                controllerName,
                _badgeModelController
            )
        );

        vm.prank(admin);
        badgeModels.updateBadgeModelController(controllerName, controllerAddress);
    }

    function testRevertsWhenNoAdminRole() public {
        string memory controllerName = "controllerName";
        address controllerAddress = vm.addr(10);

        bytes32 adminRole = 0x00;

        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, u1, adminRole)
        );

        vm.prank(u1);
        badgeModels.updateBadgeModelController(controllerName, controllerAddress);
    }

    function testRevertsWhenControllerNameEmpty() public {
        string memory controllerName = "";
        address controllerAddress = vm.addr(10);

        vm.expectRevert(LibTheBadgeModels.TheBadge__addBadgeModelController_emptyName.selector);

        vm.prank(admin);
        badgeModels.updateBadgeModelController(controllerName, controllerAddress);
    }

    function testRevertsWhenControllerAddressZero() public {
        string memory controllerName = "controllerName";
        address controllerAddress = address(0);

        vm.expectRevert(LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound.selector);

        vm.prank(admin);
        badgeModels.updateBadgeModelController(controllerName, controllerAddress);
    }
}
