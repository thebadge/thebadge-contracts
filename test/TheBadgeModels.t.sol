pragma solidity ^0.8.0;

import { Test } from "forge-std/Test.sol";
import { TheBadgeModels } from "../src/contracts/thebadge/TheBadgeModels.sol"; // Use the appropriate Solidity version
import { TheBadgeStore } from "../src/contracts/thebadge/TheBadgeStore.sol";
import { TheBadgeUsers } from "../src/contracts/thebadge/TheBadgeUsers.sol";
import { KlerosBadgeModelController } from "../src/contracts/badgeModelControllers/KlerosBadgeModelController.sol";
import { KlerosBadgeModelControllerStore } from "../src/contracts/badgeModelControllers/KlerosBadgeModelControllerStore.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";
import "forge-std/console.sol";
import "openzeppelin-contracts-upgradeable/contracts/utils/CountersUpgradeable.sol";

contract TheBadgeModelsTest is Test {
    TheBadgeModels public badgeModelsInstance;
    TheBadgeUsers public badgeUsersInstance;
    TheBadgeStore public badgeStoreInstance;
    KlerosBadgeModelController public klerosBadgeModelControllerInstance;
    address public admin = vm.addr(1);
    address public user1 = vm.addr(2);
    address public user2 = vm.addr(3);
    address public feeCollector = vm.addr(4);
    string public klerosControllerName = "Kleros";

    // Set up the contract instances before each test
    function setUp() public virtual {
        // Instantiates the store
        console.log("Initializing mockup badgeStoreInstance...");
        address theBadgeStoreImp = address(new TheBadgeStore());
        address theBadgeStoreProxy = ClonesUpgradeable.clone(theBadgeStoreImp);
        badgeStoreInstance = TheBadgeStore(payable(theBadgeStoreProxy));
        badgeStoreInstance.initialize(admin, feeCollector); //
        console.log("badgeStoreInstance initialized with address: ", address(badgeStoreInstance));

        // Instantiates the TheBadgeUsers
        console.log("Initializing mockup badgeUsersInstance...");
        address theBadgeUsersImp = address(new TheBadgeUsers());
        address theBadgeUsersProxy = ClonesUpgradeable.clone(theBadgeUsersImp);
        badgeUsersInstance = TheBadgeUsers(payable(theBadgeUsersProxy));
        badgeUsersInstance.initialize(admin, address(badgeStoreInstance));
        console.log("badgeUsersInstance initialized with address: ", address(badgeUsersInstance));

        // Instantiates the TheBadgeModels
        console.log("Initializing mockup badgeModelsInstance...");
        address badgeModelsInstanceImp = address(new TheBadgeModels());
        address theBadgeModelsProxy = ClonesUpgradeable.clone(badgeModelsInstanceImp);
        badgeModelsInstance = TheBadgeModels(payable(theBadgeModelsProxy));
        badgeModelsInstance.initialize(admin, address(badgeStoreInstance), address(badgeUsersInstance));
        console.log("badgeModelsInstance initialized with address: ", address(badgeModelsInstance));

        // Instantiates the KlerosBadgeModelController
        console.log("Initializing mockup klerosBadgeModelControllerInstance...");
        // TODO: this _badgeContractAddress should be also a instance of TheBadge.sol contract and should be initialized the same way the rest of the contracts showed here
        address _badgeContractAddress = vm.addr(5);
        address _arbitrator = vm.addr(6);
        // Address of _tcrFactory in goerli, because we use a fork of goerli we have this already instanciated
        // TODO: Maybe refactor this
        address _tcrFactory = 0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314;
        address klerosBadgeModelInstanceImp = address(new KlerosBadgeModelController());
        address klerosBadgeModelControllerProxy = ClonesUpgradeable.clone(klerosBadgeModelInstanceImp);
        klerosBadgeModelControllerInstance = KlerosBadgeModelController(payable(klerosBadgeModelControllerProxy));
        klerosBadgeModelControllerInstance.initialize(
            admin,
            _badgeContractAddress,
            address(badgeModelsInstance),
            address(badgeUsersInstance),
            _arbitrator,
            _tcrFactory
        );
        console.log(
            "klerosBadgeModelControllerInstance initialized with address: ",
            address(klerosBadgeModelControllerInstance)
        );

        // Finally adds the permissions to TheBadgeModels and TheBadgeUsers to access the store...
        console.log("Allowing TheBadgeUsers & TheBadgeModels to access the store...");
        vm.prank(admin);
        badgeStoreInstance.addPermittedContract("TheBadgeUsers", address(badgeUsersInstance));
        vm.prank(admin);
        badgeStoreInstance.addPermittedContract("TheBadgeModels", address(badgeModelsInstance));
        console.log("TheBadgeUsers & TheBadgeModels added to the store...");

        // Adds KlerosBadgeModelController to the the list of controllers on the store...
        console.log("Adding the klerosBadgeModelController to the list of supported controllers...");
        TheBadgeStore.BadgeModelController memory klerosBadgeModelController = TheBadgeStore.BadgeModelController({
            controller: address(klerosBadgeModelControllerInstance),
            paused: false,
            initialized: true
        });
        // Changes the msg.sender to be the badgeModelsInstance which is the contract allowed to run addBadgeModelController()
        vm.prank(address(badgeModelsInstance));
        badgeStoreInstance.addBadgeModelController(klerosControllerName, klerosBadgeModelController);
        console.log("KlerosBadgeModelController has been added!");

        // Finally gives the role USER_MANAGER_ROLE to the contract TheBadgeModels to allow it to call the method makeUserCreator on the contract TheBadgeUsers
        // Fore more details you can check the 01_deploy.ts script inside the /script folder
        console.log("Granting USER_MANAGER_ROLE to the TheBadgeModels contract...");
        bytes32 managerRole = keccak256("USER_MANAGER_ROLE");
        vm.prank(admin);
        badgeUsersInstance.grantRole(managerRole, address(badgeModelsInstance));
        console.log("USER_MANAGER_ROLE granted!");
    }

    function testCreateBadgeModel() public {
        // Register a user
        vm.prank(user1);
        badgeUsersInstance.registerUser("ipfs://creatorMetadata.json", false);

        // Create a badge model
        TheBadgeStore.CreateBadgeModel memory badgeModel = TheBadgeStore.CreateBadgeModel({
            metadata: "ipfs://badgeModelMetadata.json",
            controllerName: "Kleros",
            mintCreatorFee: 100, // Adjust fee as needed
            validFor: 365 days // Adjust validity period as needed
        });

        uint256[4] memory baseDeposits = [uint256(0), uint256(0), uint256(0), uint256(0)];
        uint256[3] memory stakeMultipliers = [uint256(1), uint256(1), uint256(1)];
        KlerosBadgeModelControllerStore.CreateBadgeModel memory klerosBadgeModel = KlerosBadgeModelControllerStore
            .CreateBadgeModel({
                governor: vm.addr(1),
                admin: admin,
                courtId: 0,
                numberOfJurors: 1,
                registrationMetaEvidence: "ipfs://registrationMetaEvidence.json",
                clearingMetaEvidence: "ipfs://clearingMetaEvidence.json",
                challengePeriodDuration: 0,
                baseDeposits: baseDeposits,
                stakeMultipliers: stakeMultipliers
            });

        bytes memory data = abi.encode(klerosBadgeModel);

        uint256 initialBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();

        // Perform the createBadgeModel transaction
        vm.prank(user1);
        badgeModelsInstance.createBadgeModel(badgeModel, data);

        // Check if the badge model was created
        uint256 newBadgeModelCount = badgeStoreInstance.getCurrentBadgeModelsIdCounter();
        assertTrue(newBadgeModelCount > initialBadgeModelCount, "Badge model should be created");

        // Retrieve the created badge model
        (
            address creator,
            string memory controllerName,
            bool paused,
            uint256 mintCreatorFee,
            uint256 validFor,
            uint256 mintProtocolFee,
            bool initialized,

        ) = badgeStoreInstance.badgeModels(newBadgeModelCount - 1); // Assuming the last badge model was created

        // Perform assertions
        assertEq(creator, user1, "Creator should match");
        assertEq(controllerName, badgeModel.controllerName, "Controller name should match");
        assertEq(paused, false, "Badge model should not be paused");
        assertEq(mintCreatorFee, badgeModel.mintCreatorFee, "Mint creator fee should match");
        assertEq(validFor, badgeModel.validFor, "Valid for should match");
        assertEq(
            mintProtocolFee,
            badgeStoreInstance.mintBadgeProtocolDefaultFeeInBps(),
            "Mint protocol fee should match"
        );
        assertTrue(initialized, "Badge model should be initialized");

        // TODO: Assert creation event if needed
    }
}