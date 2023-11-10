pragma solidity ^0.8.20;

import { Test } from "forge-std/Test.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";
import { TheBadgeStore } from "../../../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../../../src/contracts/thebadge/TheBadgeUsers.sol";
import { TheBadgeModels } from "../../../src/contracts/thebadge/TheBadgeModels.sol";
import { TpBadgeModelController } from "../../../src/contracts/badgeModelControllers/TpBadgeModelController.sol";
import { TpBadgeModelControllerStore } from "../../../src/contracts/badgeModelControllers/TpBadgeModelControllerStore.sol";

contract Config is Test {
    TheBadgeModels public badgeModelsInstance;
    TheBadgeUsers public badgeUsersInstance;
    TheBadgeStore public badgeStoreInstance;
    TpBadgeModelController public tpBadgeModelControllerInstance;
    TpBadgeModelControllerStore public tpBadgeModelControllerStoreInstance;
    address public admin = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    address public feeCollector = vm.addr(4);
    // TCR Factory address in goerli
    address public _tcrFactory = 0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314;
    // Kleros arbitrator address in goerli
    address public _arbitrator = 0x1128eD55ab2d796fa92D2F8E1f336d745354a77A;
    string public tpControllerName = "thirdParty";

    // Set up the contract instances before each test
    function setUp() public virtual {
        // Instantiates the store
        address theBadgeStoreImp = address(new TheBadgeStore());
        address theBadgeStoreProxy = Clones.clone(theBadgeStoreImp);
        badgeStoreInstance = TheBadgeStore(payable(theBadgeStoreProxy));
        badgeStoreInstance.initialize(admin, feeCollector); //

        // Instantiates the TheBadgeUsers
        address theBadgeUsersImp = address(new TheBadgeUsers());
        address theBadgeUsersProxy = Clones.clone(theBadgeUsersImp);
        badgeUsersInstance = TheBadgeUsers(payable(theBadgeUsersProxy));
        badgeUsersInstance.initialize(admin, address(badgeStoreInstance));

        // Instantiates the TheBadgeModels
        address badgeModelsInstanceImp = address(new TheBadgeModels());
        address theBadgeModelsProxy = Clones.clone(badgeModelsInstanceImp);
        badgeModelsInstance = TheBadgeModels(payable(theBadgeModelsProxy));
        badgeModelsInstance.initialize(admin, address(badgeStoreInstance), address(badgeUsersInstance));

        // Instantiates the TpBadgeModelControllerStore
        address tpBadgeModelControllerStoreInstanceImp = address(new TpBadgeModelControllerStore());
        address tpBadgeModelControllerStoreProxy = Clones.clone(tpBadgeModelControllerStoreInstanceImp);
        tpBadgeModelControllerStoreInstance = TpBadgeModelControllerStore(payable(tpBadgeModelControllerStoreProxy));
        tpBadgeModelControllerStoreInstance.initialize(admin, feeCollector, _arbitrator, _tcrFactory);

        // Instantiates the TpBadgeModelController
        address _badgeContractAddress = vm.addr(5);

        address tpBadgeModelControllerInstanceImp = address(new TpBadgeModelController());
        address tpBadgeModelControllerProxy = Clones.clone(tpBadgeModelControllerInstanceImp);
        tpBadgeModelControllerInstance = TpBadgeModelController(payable(tpBadgeModelControllerProxy));
        tpBadgeModelControllerInstance.initialize(
            admin,
            _badgeContractAddress,
            address(badgeModelsInstance),
            address(badgeUsersInstance),
            address(tpBadgeModelControllerStoreInstance)
        );

        // Adds the permissions to TheBadgeModels and TheBadgeUsers to access the store...
        vm.prank(admin);
        badgeStoreInstance.addPermittedContract("TheBadgeUsers", address(badgeUsersInstance));
        vm.prank(admin);
        badgeStoreInstance.addPermittedContract("TheBadgeModels", address(badgeModelsInstance));

        // Adds TpBadgeModelController to the the list of controllers on the store...
        TheBadgeStore.BadgeModelController memory tpBadgeModelController = TheBadgeStore.BadgeModelController({
            controller: address(tpBadgeModelControllerInstance),
            paused: false,
            initialized: true
        });
        // Changes the msg.sender to be the badgeModelsInstance which is the contract allowed to run addBadgeModelController()
        vm.prank(address(badgeModelsInstance));
        badgeStoreInstance.addBadgeModelController(tpControllerName, tpBadgeModelController);

        // Finally adds the permission to TpBadgeModelController to access the TpBadgeModelControllerStore...
        vm.prank(admin);
        tpBadgeModelControllerStoreInstance.addPermittedContract(
            "tpBadgeModelController",
            address(tpBadgeModelControllerInstance)
        );

        // Finally gives the role USER_MANAGER_ROLE to the contract TheBadgeModels to allow it to call the method makeUserCreator on the contract TheBadgeUsers
        // Fore more details you can check the 01_deploy.ts script inside the /script folder
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsersInstance.grantRole(managerRole, address(badgeModelsInstance));
    }
}
