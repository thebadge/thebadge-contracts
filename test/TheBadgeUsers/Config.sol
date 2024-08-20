pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsersStore } from "contracts/thebadge/TheBadgeUsersStore.sol";
import { TheBadgeUsers } from "contracts/thebadge/TheBadgeUsers.sol";
import { TheBadgeModels } from "contracts/thebadge/TheBadgeModels.sol";
import { KlerosBadgeModelController } from "contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { KlerosBadgeModelControllerStore } from "contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";

import { LibTheBadgeUsers } from "../../src/contracts/libraries/LibTheBadgeUsers.sol";
import { LibTheBadge } from "../../src/contracts/libraries/LibTheBadge.sol";
import { IBadgeModelController } from "../../src/interfaces/IBadgeModelController.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);

    TheBadgeModels public badgeModelsInstance;
    TheBadgeUsers public badgeUsersInstance;
    TheBadgeStore public badgeStoreInstance;
    TheBadgeUsers badgeUsers;
    TheBadgeStore badgeStore;
    TheBadgeUsersStore badgeUsersStore;
    KlerosBadgeModelController public klerosBadgeModelControllerInstance;
    KlerosBadgeModelControllerStore public klerosBadgeModelControllerStoreInstance;
    // TCR Factory address in sepolia
    address public _tcrFactory = 0x3FB8314C628E9afE7677946D3E23443Ce748Ac17;
    // Kleros arbitrator address in sepolia
    address public _arbitrator = 0x90992fb4E15ce0C59aEFfb376460Fda4Ee19C879;

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

        address badgeStoreProxy = Clones.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeUsersStoreProxy = Clones.clone(address(new TheBadgeUsersStore()));
        badgeUsersStore = TheBadgeUsersStore(payable(badgeUsersStoreProxy));
        badgeUsersStore.initialize(admin);

        address badgeUsersProxy = Clones.clone(address(new TheBadgeUsers()));
        badgeUsers = TheBadgeUsers(payable(badgeUsersProxy));
        badgeUsers.initialize(admin, badgeStoreProxy, badgeUsersStoreProxy);

        vm.prank(admin);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersProxy);

        vm.prank(admin);
        badgeUsersStore.addPermittedContract("TheBadgeUsers", badgeUsersProxy);

        // Instantiates the TheBadgeModels
        address badgeModelsInstanceImp = address(new TheBadgeModels());
        address theBadgeModelsProxy = Clones.clone(badgeModelsInstanceImp);
        badgeModelsInstance = TheBadgeModels(payable(theBadgeModelsProxy));
        badgeModelsInstance.initialize(admin, address(badgeStoreInstance), address(badgeUsersInstance));

        // Instantiates the KlerosBadgeModelControllerStore
        address klerosBadgeModelControllerStoreInstanceImp = address(new KlerosBadgeModelControllerStore());
        address klerosBadgeModelControllerStoreProxy = Clones.clone(klerosBadgeModelControllerStoreInstanceImp);
        klerosBadgeModelControllerStoreInstance = KlerosBadgeModelControllerStore(
            payable(klerosBadgeModelControllerStoreProxy)
        );
        klerosBadgeModelControllerStoreInstance.initialize(admin, _arbitrator, _tcrFactory);

        // Instantiates the KlerosBadgeModelController
        address _badgeContractAddress = vm.addr(5);

        address klerosBadgeModelInstanceImp = address(new KlerosBadgeModelController());
        address klerosBadgeModelControllerProxy = Clones.clone(klerosBadgeModelInstanceImp);
        klerosBadgeModelControllerInstance = KlerosBadgeModelController(payable(klerosBadgeModelControllerProxy));
        klerosBadgeModelControllerInstance.initialize(
            admin,
            _badgeContractAddress,
            address(badgeModelsInstance),
            address(klerosBadgeModelControllerStoreInstance)
        );
    }
}
