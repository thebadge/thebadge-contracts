// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsersStore } from "../../src/contracts/thebadge/TheBadgeUsersStore.sol";
import { TheBadgeUsers } from "../../src/contracts/thebadge/TheBadgeUsers.sol";
import { TheBadgeModels } from "../../src/contracts/thebadge/TheBadgeModels.sol";
import { TheBadge } from "../../src/contracts/thebadge/TheBadge.sol";
import { KlerosBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import { KlerosBadgeModelController } from "../../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { TpBadgeModelControllerStore } from "../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";
import { TpBadgeModelController } from "../../src/contracts/badgeModelControllers/TpBadgeModelController.sol";

contract Config is Test {
    address admin = vm.addr(1);
    address feeCollector = vm.addr(2);
    address u1 = vm.addr(3);
    address u2 = vm.addr(4);
    bytes32 tpMinterRole = keccak256("TP_MINTER_ROLE");

    TheBadgeStore badgeStore;
    TheBadge theBadge;
    TheBadgeUsersStore badgeUsersStore;
    TheBadgeUsers badgeUsers;
    TheBadgeModels badgeModels;
    KlerosBadgeModelController klerosBadgeModelControllerInstance;
    KlerosBadgeModelControllerStore klerosBadgeModelControllerStoreInstance;
    TpBadgeModelController tpBadgeModelControllerInstance;
    TpBadgeModelControllerStore tpBadgeModelControllerStoreInstance;

    string public klerosControllerName = "kleros";
    string public tpControllerName = "thirdParty";
    // TCR Factory address in sepolia
    address public _tcrFactory = 0x3FB8314C628E9afE7677946D3E23443Ce748Ac17;
    // Kleros arbitrator address in sepolia
    address public _arbitrator = 0x90992fb4E15ce0C59aEFfb376460Fda4Ee19C879;

    function setUp() public {
        vm.deal(u1, 1 ether);
        vm.deal(u2, 1 ether);
        vm.deal(admin, 1 ether);
        vm.deal(feeCollector, 0 ether);

        address badgeUsersStoreProxy = Clones.clone(address(new TheBadgeUsersStore()));
        badgeUsersStore = TheBadgeUsersStore(payable(badgeUsersStoreProxy));
        badgeUsersStore.initialize(admin);

        address badgeStoreProxy = Clones.clone(address(new TheBadgeStore()));
        badgeStore = TheBadgeStore(payable(badgeStoreProxy));
        badgeStore.initialize(admin, feeCollector);

        address badgeUsersProxy = Clones.clone(address(new TheBadgeUsers()));
        badgeUsers = TheBadgeUsers(payable(badgeUsersProxy));
        badgeUsers.initialize(admin, badgeStoreProxy, badgeUsersStoreProxy);

        address badgeModelsProxy = Clones.clone(address(new TheBadgeModels()));
        badgeModels = TheBadgeModels(payable(badgeModelsProxy));
        badgeModels.initialize(admin, badgeStoreProxy, badgeUsersProxy);

        address badgeProxy = Clones.clone(address(new TheBadge()));
        theBadge = TheBadge(payable(badgeProxy));
        theBadge.initialize(admin, badgeStoreProxy, badgeUsersProxy);

        vm.startPrank(admin);
        badgeStore.addPermittedContract("TheBadge", address(theBadge));
        badgeStore.addPermittedContract("TheBadgeModels", address(badgeModels));
        vm.stopPrank();

        // Adds the permission to TheBadgeUsers to access the badgeUsersStore...
        vm.startPrank(admin);
        badgeUsersStore.addPermittedContract("TheBadgeUsers", address(badgeUsers));
        vm.stopPrank();

        setUpControllers();

        vm.startPrank(admin);
        // Adds klerosBadgeModelController to theBadgeModels
        badgeModels.addBadgeModelController(klerosControllerName, address(klerosBadgeModelControllerInstance));

        // Adds thirdPartyBadgeModelController to theBadgeModels
        badgeModels.addBadgeModelController(tpControllerName, address(tpBadgeModelControllerInstance));
        vm.stopPrank();

        // Gives the role USER_MANAGER_ROLE to the contract TheBadgeModels to allow it to call the method makeUserCreator on the contract TheBadgeUsers
        // Fore more details you can check the 01_deploy.ts script inside the /script folder
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsers.grantRole(managerRole, address(badgeModels));

        // Finally gives the role TP_MINTER_ROLE to the contract TheBadgeModels to allow it to call mintOnBehalf method for thirdParty badges
        vm.prank(admin);
        theBadge.grantRole(tpMinterRole, address(admin));
    }

    function setUpControllers() public {
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
            address(theBadge),
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
            address(theBadge),
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
    }
}
