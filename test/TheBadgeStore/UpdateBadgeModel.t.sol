pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeModels.sol";

import { Config } from "./Config.sol";

contract UpdateBadgeModel is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        address creator = vm.addr(12);
        string memory controllerName = "controllerName";
        bool paused = false;
        uint256 mintCreatorFee = 0.1 ether;
        uint256 validFor = 100;
        uint256 mintProtocolFee = 0.2 ether;
        bool initialized = true;
        string memory version = "v1";

        TheBadgeStore.BadgeModel memory badgeModel = TheBadgeStore.BadgeModel(
            creator,
            controllerName,
            paused,
            mintCreatorFee,
            validFor,
            mintProtocolFee,
            initialized,
            version
        );

        vm.prank(badgeUsersAddress);
        badgeStore.addBadgeModel(badgeModel);

        TheBadgeStore.BadgeModel memory updatedBadgeModel = TheBadgeStore.BadgeModel(
            creator,
            controllerName,
            true,
            1 ether,
            validFor,
            2 ether,
            initialized,
            version
        );

        vm.prank(badgeUsersAddress);
        badgeStore.updateBadgeModel(0, updatedBadgeModel);

        (, , bool _paused, uint256 _mintCreatorFee, , uint256 _mintProtocolFee, , ) = badgeStore.badgeModels(0);

        assertEq(_paused, true);
        assertEq(_mintCreatorFee, 1 ether);
        assertEq(_mintProtocolFee, 2 ether);
    }

    function testRevertsWhenNotPermittedContract() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        address creator = vm.addr(12);
        string memory controllerName = "controllerName";
        bool paused = false;
        uint256 mintCreatorFee = 0.1 ether;
        uint256 validFor = 100;
        uint256 mintProtocolFee = 0.2 ether;
        bool initialized = true;
        string memory version = "v1";

        TheBadgeStore.BadgeModel memory badgeModel = TheBadgeStore.BadgeModel(
            creator,
            controllerName,
            paused,
            mintCreatorFee,
            validFor,
            mintProtocolFee,
            initialized,
            version
        );

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.updateBadgeModel(0, badgeModel);
    }

    function testRevertsWhenModelNotFound() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        address creator = vm.addr(12);
        string memory controllerName = "controllerName";
        bool paused = false;
        uint256 mintCreatorFee = 0.1 ether;
        uint256 validFor = 100;
        uint256 mintProtocolFee = 0.2 ether;
        bool initialized = true;
        string memory version = "v1";

        TheBadgeStore.BadgeModel memory updateBadgeModel = TheBadgeStore.BadgeModel(
            creator,
            controllerName,
            paused,
            mintCreatorFee,
            validFor,
            mintProtocolFee,
            initialized,
            version
        );

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound.selector);
        badgeStore.updateBadgeModel(0, updateBadgeModel);
    }
}
