pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { Config } from "./Config.sol";

contract CreateBadgeModel is Config {
    function testWorks() public {
        string memory controllerName = "controllerName";
        address controllerAddress = vm.addr(10);

        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: controllerName,
            mintCreatorFee: 0.2e18,
            validFor: 100
        });

        bytes memory data = "evidence";

        uint256 fee = 0.1e18;
        vm.prank(address(badgeModels));
        badgeStore.updateCreateBadgeModelProtocolFee(fee);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // create BadgeModelController
        vm.prank(admin);
        badgeModels.addBadgeModelController(controllerName, controllerAddress);

        // register user
        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        // mock call to controller contract
        // this logic is going to be tested in the controller contract test
        vm.mockCall(
            controllerAddress,
            abi.encodeWithSelector(IBadgeModelController.createBadgeModel.selector),
            abi.encode()
        );

        TheBadgeStore.BadgeModel memory _badgeModel = TheBadgeStore.BadgeModel(
            u1,
            args.controllerName,
            false,
            args.mintCreatorFee,
            args.validFor,
            1000,
            true,
            "v1.0.0"
        );

        // check badgeStore.addBadgeModel is being called with expected args
        vm.expectCall(address(badgeStore), abi.encodeWithSelector(TheBadgeStore.addBadgeModel.selector, _badgeModel));

        // check that the mocked contract function is being called with expected args
        vm.expectCall(
            controllerAddress,
            abi.encodeWithSelector(IBadgeModelController.createBadgeModel.selector, u1, 0, data)
        );

        badgeModels.createBadgeModel{ value: fee }(args, data);
        vm.stopPrank();

        // check fee is being collected
        assertEq(feeCollector.balance, fee);

        // check user becomes creator
        TheBadgeStore.User memory _user = badgeStore.getUser(u1);
        assertEq(_user.isCreator, true);
    }

    function testRevertsWhenNotRegisteredUser() public {
        string memory controllerName = "controllerName";

        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: controllerName,
            mintCreatorFee: 0.2e18,
            validFor: 100
        });

        bytes memory data = "evidence";
        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyUser_userNotFound.selector);

        vm.prank(u1);
        badgeModels.createBadgeModel(args, data);
    }

    function testRevertsWhenNotExistBadgeModelController() public {
        string memory controllerName = "controllerName";

        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: controllerName,
            mintCreatorFee: 0.2e18,
            validFor: 100
        });

        bytes memory data = "evidence";

        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        vm.expectRevert(LibTheBadge.TheBadge__controller_invalidController.selector);

        badgeModels.createBadgeModel(args, data);
        vm.stopPrank();
    }

    function testRevertsWhenWrongFee() public {
        string memory controllerName = "controllerName";
        address controllerAddress = vm.addr(10);

        TheBadgeStore.CreateBadgeModel memory args = TheBadgeStore.CreateBadgeModel({
            metadata: "metadata",
            controllerName: controllerName,
            mintCreatorFee: 0.2e18,
            validFor: 100
        });

        bytes memory data = "evidence";

        uint256 fee = 0.1e18;
        vm.prank(address(badgeModels));
        badgeStore.updateCreateBadgeModelProtocolFee(fee);

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // create BadgeModelController
        vm.prank(admin);
        badgeModels.addBadgeModelController(controllerName, controllerAddress);

        // register user
        vm.startPrank(u1);
        badgeUsers.registerUser("user metadata", false);

        // check reverts when fee not enough
        vm.expectRevert(LibTheBadgeModels.TheBadge__createBadgeModel_wrongValue.selector);

        badgeModels.createBadgeModel(args, data);
        vm.stopPrank();
    }
}
