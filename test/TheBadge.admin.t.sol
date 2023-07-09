// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import { Config, TheBadge, TheBadgeLogic } from "./utils/Config.sol";

contract TheBadgeTestAdmin is Config {
    // function mint shoul work
    //   function mint(uint256 badgeModelId, address account, string memory tokenURI, bytes memory data) external payable {

    function test_mint_shouldWork() public {
        vm.prank(admin);
        bytes memory _data = keccak256(abi.encodePacked("test", "test"));
        theBadge.mint(1, vegeta, "test", _data);
        assertEq(theBadge.balanceOf(vegeta), 1);
    }

    // test pause() and unpause() -- should work
    function test_pause_shouldWork() public {
        // Verify that the pause() function is initially in an unpaused state
        assertFalse(theBadge.paused());
        // Pause the contract
        vm.prank(address(this));
        theBadge.pause();

        // Verify that the pause() function is now in a paused state
        assertTrue(theBadge.paused());

        //veriry that unpause can be called only by the pauser role
        vm.prank(address(this));
        theBadge.unpause();
        assertFalse(theBadge.paused());
    }

    // test pause() -- only should be call by (PAUSER_ROLE, msg.sender)
    function test_pause_shouldRevert() public {
        vm.prank(admin);
        vm.expectRevert();
        theBadge.pause();
    }

    // test unpause() -- only should be call by (UNPAUSER_ROLE, msg.sender)
    function test_unpause_shouldRevert() public {
        vm.prank(admin);
        vm.expectRevert();
        theBadge.unpause();
    }

    // // Test updateFees method by calling it from an account that is not an admin and
    // // verifying that the call is reverted.
    function test_updateFees_notAdmin() public {
        vm.prank(vegeta);
        vm.expectRevert();
        theBadge.updateBadgeModelFee(0, 5);
    }

    // // Test updateFees method by calling it as the admin with address different than zero and
    // // verifying that the addresses are updated properly
    //TODO:
    // function test_updateFees_shouldWork() public {
    //     vm.prank(admin);
    //     theBadge.updateBadgeModelFee(0, 5);
    //     assertEq(theBadge.badgeModel(0).mintCreatorFee, 5);
    // }

    // // Test setBadgeTypeController method by calling it from a non admin address and
    // // verifying that reverts
    // function test_setBadgeTypeController_notAdmin() public {
    //     vm.prank(vegeta);
    //     vm.expectRevert(TheBadge.TheBadge__onlyAdmin_senderIsNotAdmin.selector);
    //     theBadge.setBadgeTypeController("test", address(1));
    // }
    // // Test setBadgeTypeController method by calling it from an admin address and
    // // verifying that reverts if controller address is 0.
    // function test_setBadgeTypeController_zeroAddress() public {
    //     vm.prank(admin);
    //     vm.expectRevert(TheBadge.TheBadge__setBadgeTypeController_notFound.selector);
    //     theBadge.setBadgeTypeController("test", address(0));
    // }
    // // Test setBadgeTypeController method by calling it from an admin address and
    // // verifying that reverts if controller address is 0.
    // function test_setBadgeTypeController_emptyName() public {
    //     vm.prank(admin);
    //     vm.expectRevert(TheBadge.TheBadge__setBadgeTypeController_emptyName.selector);
    //     theBadge.setBadgeTypeController("", address(1));
    // }
    // // Test setBadgeTypeController method by calling it from an admin address and
    // // verifying that reverts if the controller name is already set
    // function test_setBadgeTypeController_alreadySet() public {
    //     vm.prank(admin);
    //     vm.expectRevert(TheBadge.TheBadge__setBadgeTypeController_alreadySet.selector);
    //     theBadge.setBadgeTypeController("kleros", address(2));
    // }
    // // Test setBadgeTypeController method by calling it from an admin address and
    // // verifying that the controller is set
    // function test_setBadgeTypeController_shouldWork() public {
    //     vm.prank(admin);
    //     theBadge.setBadgeTypeController("test", address(5));
    //     (address controller, ) = theBadge.badgeTypeController("test");
    //     assertEq(controller, address(5));
    // }
    // // Test setControllerStatus method by calling it from an non admin address and
    // // verifying that the call reverts
    function test_setControllerStatus_notAdmin() public {
        vm.prank(vegeta);
        vm.expectRevert();
        theBadge.setControllerStatus("test", false);
    }

    // Test setControllerStatus method by calling it from an admin address
    function test_setControllerStatus_notFound() public {
        vm.prank(vegeta);
        vm.expectRevert();
        theBadge.setControllerStatus("test", false);
    }

    // // Test setControllerStatus method by calling it from an admin address should work

    function test_setControllerStatus_shouldWork() public {
        vm.prank(admin);
        theBadge.setControllerStatus("kleros", true);
        (, bool paused) = theBadge.badgeModelController("kleros");
        assertEq(paused, true);

        vm.prank(admin);
        theBadge.setControllerStatus("kleros", false);
        (, bool isNotPaused) = theBadge.badgeModelController("kleros");
        assertEq(isNotPaused, false);
    }
}
// Test updateAddresses method by calling it from an account that is not an admin and
// verifying that the call is reverted.
// function test_updateAddresses_notAdmin() public {
//     vm.prank(vegeta);
//     vm.expectRevert();
//     theBadge.updateAddresses(address(1), address(2));
// }
// // Test updateAddresses method by calling it as the admin with address zero and
// // verifying that the call is reverted with a proper error.
// function test_updateAddresses_invalidAddress() public {
//     vm.prank(admin);
//     vm.expectRevert(TheBadge.TheBadge__updateAddresses_paramAddressesCanNotBeZero.selector);
//     theBadge.updateAddresses(address(0), address(0));
// }
// // Test updateAddresses method by calling it as the admin with address different than zero and
// // verifying that the addresses are updated properly
// function test_updateAddresses_shouldWork() public {
//     vm.prank(admin);
//     theBadge.updateAddresses(address(1), address(2));
//     assertEq(theBadge.admin(), address(1));
//     assertEq(theBadge.feeCollector(), address(2));
// }
