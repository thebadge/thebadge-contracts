pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract AddBadgeModel is Config {
    function testWorks() public {
        // fake TheBadgeUsers Proxy
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        address creator = vm.addr(12);
        string memory controllerName = "controllerName";

        {
            bool paused = false;
            uint256 mintCreatorFee = 0.1 ether;
            uint256 validFor = 100;
            uint256 mintProtocolFee = 0.2 ether;
            bool initialized = true;
            uint256 version = 1;
            bool suspended = false;
            bool deprecated = false;

            TheBadgeStore.BadgeModel memory badgeModel = TheBadgeStore.BadgeModel(
                creator,
                controllerName,
                paused,
                mintCreatorFee,
                validFor,
                mintProtocolFee,
                initialized,
                version,
                suspended,
                deprecated,
                "ipfs://"
            );

            vm.prank(badgeUsersAddress);
            badgeStore.addBadgeModel(badgeModel);
        }

        (
            address _creator,
            string memory _controllerName,
            bool _paused,
            uint256 _mintCreatorFee,
            uint256 _validFor,
            uint256 _mintProtocolFee,
            bool _initialized,
            uint256 _version,
            bool _suspended,
            bool _deprecated,
            string memory _metadata
        ) = badgeStore.badgeModels(0);

        assertEq(_creator, creator);
        assertEq(_controllerName, controllerName);
        assertEq(_paused, false);
        assertEq(_mintCreatorFee, 0.1 ether);
        assertEq(_validFor, 100);
        assertEq(_mintProtocolFee, 0.2 ether);
        assertEq(_initialized, true);
        assertEq(_version, 1);
        assertEq(_suspended, false);
        assertEq(_deprecated, false);
        assertEq(_metadata, "ipfs://");

        uint256 counter = badgeStore.getCurrentBadgeModelsIdCounter();

        assertEq(counter, 1);
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
        uint256 version = 1;
        bool suspended = false;
        bool deprecated = false;

        TheBadgeStore.BadgeModel memory badgeModel = TheBadgeStore.BadgeModel(
            creator,
            controllerName,
            paused,
            mintCreatorFee,
            validFor,
            mintProtocolFee,
            initialized,
            version,
            suspended,
            deprecated,
            "ipfs://"
        );

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.addBadgeModel(badgeModel);
    }
}
