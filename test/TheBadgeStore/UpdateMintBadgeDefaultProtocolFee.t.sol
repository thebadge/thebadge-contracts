pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Config } from "./Config.sol";

contract UpdateMintBadgeDefaultProtocolFee is Config {
    function testWorks() public {
        address badgeUsersAddress = vm.addr(10);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersAddress);

        uint256 fee = 1 ether;

        vm.prank(badgeUsersAddress);
        badgeStore.updateMintBadgeDefaultProtocolFee(fee);

        assertEq(badgeStore.mintBadgeProtocolDefaultFeeInBps(), fee);
    }

    function testRevertsWhenNotPermittedContract() public {
        address badgeUsersAddress = vm.addr(10);

        uint256 fee = 1 ether;

        vm.prank(badgeUsersAddress);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_OperationNotPermitted.selector);
        badgeStore.updateMintBadgeDefaultProtocolFee(fee);
    }
}
