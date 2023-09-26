pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { ClonesUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../../src/contracts/thebadge/TheBadgeUsers.sol";
import "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import "../../src/contracts/libraries/LibTheBadge.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";

contract Config is Test {
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
    event UserVerificationRequested(address indexed user, string metadata, string controllerName);

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
}