pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsersStore } from "../../src/contracts/thebadge/TheBadgeUsersStore.sol";
import { TheBadgeUsers } from "../../src/contracts/thebadge/TheBadgeUsers.sol";
import { TheBadgeModels } from "../../src/contracts/thebadge/TheBadgeModels.sol";
import { KlerosBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import { KlerosBadgeModelController } from "../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { TpBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";
import { TpBadgeModelController } from "../../src/contracts/badgeModelControllers/TpBadgeModelController.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);
    // TCR Factory address in sepolia
    address public _tcrFactory = 0x3FB8314C628E9afE7677946D3E23443Ce748Ac17;
    // Kleros arbitrator address in sepolia
    address public _arbitrator = 0x90992fb4E15ce0C59aEFfb376460Fda4Ee19C879;
    string public klerosControllerName = "kleros";
    string public tpControllerName = "thirdParty";

    TheBadgeStore badgeStore;
    TheBadgeUsersStore badgeUsersStore;
    TheBadgeUsers badgeUsers;
    TheBadgeModels badgeModels;
    KlerosBadgeModelController klerosBadgeModelControllerInstance;
    KlerosBadgeModelControllerStore klerosBadgeModelControllerStoreInstance;
    TpBadgeModelController tpBadgeModelControllerInstance;
    TpBadgeModelControllerStore tpBadgeModelControllerStoreInstance;
    address _badgeContractAddress = vm.addr(5);

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

        address badgeModelsProxy = Clones.clone(address(new TheBadgeModels()));
        badgeModels = TheBadgeModels(payable(badgeModelsProxy));
        badgeModels.initialize(admin, badgeStoreProxy, badgeUsersProxy);

        vm.startPrank(admin);
        badgeStore.addPermittedContract("TheBadgeModels", badgeModelsProxy);
        badgeStore.addPermittedContract("TheBadgeUsers", badgeUsersProxy);
        vm.stopPrank();

        // Instantiates the KlerosBadgeModelControllerStore
        address klerosBadgeModelControllerStoreInstanceImp = address(new KlerosBadgeModelControllerStore());
        address klerosBadgeModelControllerStoreProxy = Clones.clone(klerosBadgeModelControllerStoreInstanceImp);
        klerosBadgeModelControllerStoreInstance = KlerosBadgeModelControllerStore(
            payable(klerosBadgeModelControllerStoreProxy)
        );
        klerosBadgeModelControllerStoreInstance.initialize(admin, _arbitrator, _tcrFactory);

        // Instantiates the KlerosBadgeModelController
        address klerosBadgeModelInstanceImp = address(new KlerosBadgeModelController());
        address klerosBadgeModelControllerProxy = Clones.clone(klerosBadgeModelInstanceImp);
        klerosBadgeModelControllerInstance = KlerosBadgeModelController(payable(klerosBadgeModelControllerProxy));
        klerosBadgeModelControllerInstance.initialize(
            admin,
            _badgeContractAddress,
            address(badgeModels),
            address(klerosBadgeModelControllerStoreInstance)
        );

        // Finally adds the permission to klerosBadgeModelControllerInstance to access the klerosBadgeModelControllerStoreInstance...
        vm.prank(admin);
        klerosBadgeModelControllerStoreInstance.addPermittedContract(
            klerosControllerName,
            address(klerosBadgeModelControllerInstance)
        );

        // Instantiates the TpBadgeModelControllerStore
        address tpBadgeModelControllerStoreInstanceImp = address(new TpBadgeModelControllerStore());
        address tpBadgeModelControllerStoreProxy = Clones.clone(tpBadgeModelControllerStoreInstanceImp);
        tpBadgeModelControllerStoreInstance = TpBadgeModelControllerStore(payable(tpBadgeModelControllerStoreProxy));
        tpBadgeModelControllerStoreInstance.initialize(admin, feeCollector, _arbitrator, _tcrFactory);

        // Instantiates the TpBadgeModelController
        address tpBadgeModelControllerInstanceImp = address(new TpBadgeModelController());
        address tpBadgeModelControllerProxy = Clones.clone(tpBadgeModelControllerInstanceImp);
        tpBadgeModelControllerInstance = TpBadgeModelController(payable(tpBadgeModelControllerProxy));
        tpBadgeModelControllerInstance.initialize(
            admin,
            _badgeContractAddress,
            address(badgeModels),
            address(tpBadgeModelControllerStoreInstance),
            address(badgeUsers)
        );

        // Finally adds the permission to TpBadgeModelController to access the TpBadgeModelControllerStore...
        vm.prank(admin);
        tpBadgeModelControllerStoreInstance.addPermittedContract(
            tpControllerName,
            address(tpBadgeModelControllerInstance)
        );

        // Adds KlerosBadgeModelController to the the list of controllers on the store...
        TheBadgeStore.BadgeModelController memory klerosBadgeModelController = TheBadgeStore.BadgeModelController({
            controller: address(klerosBadgeModelControllerInstance),
            paused: false,
            initialized: true
        });
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModelController(klerosControllerName, klerosBadgeModelController);

        // Adds TpBadgeModelController to the the list of controllers on the store...
        TheBadgeStore.BadgeModelController memory tpBadgeModelController = TheBadgeStore.BadgeModelController({
            controller: address(tpBadgeModelControllerInstance),
            paused: false,
            initialized: true
        });
        vm.prank(address(badgeModels));
        badgeStore.addBadgeModelController(tpControllerName, tpBadgeModelController);

        // Finally adds the permission to TpBadgeModelController to access the badgeUsersStore...
        vm.startPrank(admin);
        badgeUsersStore.addPermittedContract("TheBadgeUsers", address(badgeUsers));
        badgeUsersStore.addPermittedContract("TheBadgeModels", address(badgeModels));
        badgeUsersStore.addPermittedContract(klerosControllerName, address(klerosBadgeModelControllerInstance));
        badgeUsersStore.addPermittedContract(tpControllerName, address(tpBadgeModelControllerInstance));
        vm.stopPrank();
    }
}
