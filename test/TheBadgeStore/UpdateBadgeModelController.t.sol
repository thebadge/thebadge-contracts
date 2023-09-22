pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { Config } from "./Config.sol";

contract UpdateBadgeModelController is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory controllerName = "ControllerName";

        address controller = vm.addr(11);

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
            false,
            false
        );

        // add
        vm.prank(badgeUsersAddress);
        badgeStore.addBadgeModelController(controllerName, badgeModelController);

        address newController = vm.addr(12);

        TheBadgeStore.BadgeModelController memory updatedBadgeModelController = TheBadgeStore.BadgeModelController(
            newController,
            false,
            false
        );

        // update
        vm.prank(badgeUsersAddress);
        badgeStore.updateBadgeModelController(controllerName, updatedBadgeModelController);

        (address _controller, bool _paused, bool _initialized) = badgeStore.badgeModelControllers(controllerName);

        assertEq(_controller, newController);
        assertEq(_paused, false);
        assertEq(_initialized, false);

        (address _controller2, bool _paused2, bool _initialized2) = badgeStore.badgeModelControllersByAddress(
            newController
        );

        assertEq(_controller2, newController);
        assertEq(_paused2, false);
        assertEq(_initialized2, false);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        string memory controllerName = "ControllerName";

        address controller = vm.addr(11);

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
            false,
            false
        );

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.updateBadgeModelController(controllerName, badgeModelController);
    }

    function testRevertsWhenControllerNotFound() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        string memory controllerName = "ControllerName";

        address controller = vm.addr(11);

        TheBadgeStore.BadgeModelController memory badgeModelController = TheBadgeStore.BadgeModelController(
            controller,
            false,
            false
        );

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeModels.TheBadge__addBadgeModelController_notFound.selector);
        badgeStore.updateBadgeModelController(controllerName, badgeModelController);
    }
}
