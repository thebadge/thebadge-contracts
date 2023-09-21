pragma solidity ^0.8.0;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadge.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";
import { Config } from "./Config.sol";

contract RegisterUser is Config {
    function testRegisterUser() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        vm.expectEmit(true, false, false, true);
        emit UserRegistered(u1, metadata);
        badgeUsers.registerUser(metadata, false);

        (string memory _metadata, bool _isCompany, bool _isCreator, bool _suspended, bool _initialized) = badgeStore
            .registeredUsers(u1);

        assertEq(_metadata, metadata);
        assertEq(_isCompany, false);
        assertEq(_isCreator, false);
        assertEq(_suspended, false);
        assertEq(_initialized, true);
    }

    function testRevertsRegisterUserWhenAlreadyExist() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered.selector);
        badgeUsers.registerUser(metadata, false);
    }

    function testRevertsRegisterUserWhenProtocolFeeAndWrongValue() public {
        vm.prank(address(badgeUsers));
        badgeStore.updateRegisterCreatorProtocolFee(0.2 ether);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__registerUser_wrongValue.selector);
        badgeUsers.registerUser(metadata, false);
    }

    function testRegisterUserWhenProtocolFee() public {
        vm.prank(address(badgeUsers));
        badgeStore.updateRegisterCreatorProtocolFee(0.2 ether);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);

        // check event emitted
        vm.expectEmit(true, true, true, true);
        emit PaymentMade(feeCollector, u1, 0.2 ether, LibTheBadge.PaymentType.UserRegistrationFee, 0, "0x");
        badgeUsers.registerUser{ value: 0.2 ether }(metadata, false);

        // check feeCollector receives the fee
        assertEq(feeCollector.balance, 0.2 ether);
    }
}
