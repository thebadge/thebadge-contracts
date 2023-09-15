pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { TheBadgeStore } from "../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../src/contracts/thebadge/TheBadgeUsers.sol";
import "../src/contracts/libraries/LibTheBadgeUsers.sol";
import "../src/contracts/libraries/LibTheBadge.sol";

contract TheBadgeUsersTest is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeUsers badgeUsers;
    TheBadgeStore badgeStore;

    event UserRegistered(address indexed user, string metadata);
    event PaymentMade(
        address indexed recipient,
        address payer,
        uint256 amount,
        LibTheBadge.PaymentType indexed paymentType,
        uint256 indexed badgeModelId,
        string controllerName
    );
    event UpdatedUser(address indexed userAddress, string metadata, bool suspended, bool isCreator, bool deleted);

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeStoreProxy = ClonesUpgradeable.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeUsersProxy = ClonesUpgradeable.clone(address(new TheBadgeUsers()));
        badgeUsers = TheBadgeUsers(payable(badgeUsersProxy));
        badgeUsers.initialize(admin, badgeStoreProxy);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersProxy);
    }

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

    function testUpdateUser() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.prank(admin);

        vm.expectEmit(true, false, false, true);
        emit UpdatedUser(u1, newMetadata, false, false, false);

        badgeUsers.updateUser(u1, newMetadata);

        (string memory _metadata, , , , ) = badgeStore.registeredUsers(u1);

        assertEq(_metadata, newMetadata);
    }

    function testRevertsUpdateUserWhenNotAdminRole() public {
        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.prank(u1);
        // TODO: find a way to expect the exact revert
        vm.expectRevert();
        badgeUsers.updateUser(u1, newMetadata);
    }

    function testRevertsUpdateUserWhenUserNotFound() public {
        string memory newMetadata = "ipfs://creatorMetadata.json";

        vm.prank(admin);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.updateUser(u1, newMetadata);
    }

    function testSuspendUser() public {
        bytes32 pauseRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauseRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        badgeUsers.suspendUser(u1, true);

        (, , , bool _suspended, ) = badgeStore.registeredUsers(u1);

        assertEq(_suspended, true);
    }

    function testRevertsSuspendUserWhenUserNotFound() public {
        bytes32 pauseRole = keccak256("PAUSER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(pauseRole, u2);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.suspendUser(u1, true);
    }

    function testMakeUserCreator() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        vm.expectEmit(true, false, false, true);
        emit UpdatedUser(u1, metadata, false, true, false);
        badgeUsers.makeUserCreator(u1);

        (, , bool _isCreator, , ) = badgeStore.registeredUsers(u1);

        assertEq(_isCreator, true);
    }

    function testRevertsMakeUserCreatorWhenUserNotFound() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__updateUser_notFound.selector);
        badgeUsers.makeUserCreator(u1);
    }

    function testRevertsMakeUserCreatorWhenUserAlreadyCreator() public {
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, u2);

        string memory metadata = "ipfs://creatorMetadata.json";
        vm.prank(u1);
        badgeUsers.registerUser(metadata, false);

        vm.prank(u2);
        badgeUsers.makeUserCreator(u1);

        vm.prank(u2);
        vm.expectRevert(LibTheBadgeUsers.TheBadge__onlyCreator_senderIsAlreadyACreator.selector);
        badgeUsers.makeUserCreator(u1);
    }
}
