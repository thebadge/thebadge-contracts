pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { LibTheBadgeModels } from "../../src/contracts/libraries/LibTheBadgeModels.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { Config } from "./Config.sol";

contract UpdateBadgeModelProtocolFee is Config {
    event BadgeModelUpdated(uint256 indexed badgeModelId);

    function testWorks() public {
        uint256 badgeModelId = 0;

        // grant USER_MANAGER_ROLE to badgeModels
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // add badge model
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModel(
            TheBadgeStore.BadgeModel(u1, "ControllerName", false, 0.2e18, 100, 1000, true, "v1.0.0")
        );

        vm.expectEmit(true, false, false, true);
        emit BadgeModelUpdated(badgeModelId);

        uint256 newProtocolFee = 0.5e18;

        vm.prank(admin);
        badgeModels.updateBadgeModelProtocolFee(badgeModelId, newProtocolFee);

        TheBadgeStore.BadgeModel memory _badgeModel = badgeStore.getBadgeModel(badgeModelId);

        assertEq(_badgeModel.mintProtocolFee, newProtocolFee);
    }

    function testRevertsWhenNotFound() public {
        uint256 badgeModelId = 0;
        uint256 newProtocolFee = 0.5e18;

        vm.expectRevert(LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound.selector);

        vm.prank(admin);
        badgeModels.updateBadgeModelProtocolFee(badgeModelId, newProtocolFee);
    }
}
