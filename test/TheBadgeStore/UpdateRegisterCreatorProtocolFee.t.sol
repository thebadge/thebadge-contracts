pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract UpdateRegisterCreatorProtocolFee is Config {
    function testWorks() public {
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        uint256 fee = 1 ether;

        vm.prank(badgeUsersAddress);
        badgeStore.updateRegisterCreatorProtocolFee(fee);

        assertEq(badgeStore.registerUserProtocolFee(), fee);
    }

    function testRevertsWhenNotPermittedContract() public {
        address badgeUsersAddress = vm.addr(10);

        uint256 fee = 1 ether;

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.updateRegisterCreatorProtocolFee(fee);
    }
}
