pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { Config } from "./Config.sol";

contract AddBadgeModelController is Config {
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

        vm.prank(badgeUsersAddress);
        badgeStore.addBadgeModelController(controllerName, badgeModelController);

        (address _controller, bool _paused, bool _initialized) = badgeStore.badgeModelControllers(controllerName);

        assertEq(_controller, controller);
        assertEq(_paused, false);
        assertEq(_initialized, false);

        (address _controller2, bool _paused2, bool _initialized2) = badgeStore.badgeModelControllersByAddress(
            controller
        );

        assertEq(_controller2, controller);
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
        badgeStore.addBadgeModelController(controllerName, badgeModelController);
    }

    function testRevertsWhenAlreadyAddedController() public {
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
        badgeStore.addBadgeModelController(controllerName, badgeModelController);

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeModels.TheBadge__addBadgeModelController_alreadySet.selector);
        badgeStore.addBadgeModelController(controllerName, badgeModelController);
    }
}
