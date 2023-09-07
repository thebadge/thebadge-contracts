// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

// TODO: Maybe we can use abstract classes to type the store
contract TheBadgeStore is TheBadgeRoles, OwnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal badgeModelIdsCounter;
    CountersUpgradeable.Counter internal badgeIdsCounter;

    // TODO: does this var makes sense? it was thought to define a min value to mint a badge.
    // For example, if the badge is going to have a cost (it can be free) it has to be bigger than this variable.
    // badgeModel1 = mint cost is 4 because minBadgeMintValue is 4.
    // uint256 public minBadgeMintValue;
    uint256 public registerUserProtocolFee;
    uint256 public createBadgeModelProtocolFee;
    uint256 public mintBadgeProtocolDefaultFeeInBps;
    address public feeCollector;

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param metadata information related with the user.
     * @param isCompany true if the user is a company, otherwise is false (default value)
     * @param isCreator true if the user has created at least one badge model
     * @param suspended If true, the user is not allowed to do any actions and if it's a creator, their badges are not mintable anymore.
     * @param initialized When the struct is created its true, if the struct was never initialized, its false, used in validations
     */
    struct User {
        string metadata;
        bool isCompany;
        bool isCreator;
        bool suspended;
        bool initialized;
    }

    /**
     * @param controller the smart contract that controls a badge model.
     * @param paused if the controller is paused, no operations can be done
     * @param initialized  When the struct is created its true, if the struct was never initialized, its false, used in validations
     */
    struct BadgeModelController {
        address controller;
        bool paused;
        bool initialized;
    }

    /**
     * Struct to use as arg to create a badge model
     */
    struct CreateBadgeModel {
        string metadata;
        string controllerName;
        uint256 mintCreatorFee;
        uint256 validFor;
    }

    /**
     * Struct to store generic information of a badge model.
     */
    struct BadgeModel {
        address creator;
        string controllerName;
        bool paused;
        uint256 mintCreatorFee; // in bps (%). It is taken from mintCreatorFee
        uint256 validFor;
        uint256 mintProtocolFee; // amount that the protocol will charge for this
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
        string version; // The version of the badgeModel, used in case of updates.
    }

    struct Badge {
        uint256 badgeModelId;
        address account;
        uint256 dueDate;
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
    }

    mapping(address => User) public registeredUsers;
    mapping(string => BadgeModelController) public badgeModelControllers;
    mapping(uint256 => BadgeModel) public badgeModels;
    mapping(uint256 => Badge) public badges;
    mapping(uint256 => mapping(address => uint256[])) public userMintedBadgesByBadgeModel;

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyRegisteredUser(address _user) {
        User storage user = registeredUsers[_user];
        if (bytes(user.metadata).length == 0) {
            revert TheBadge__onlyUser_userNotFound();
        }
        _;
    }

    modifier onlyRegisteredBadgeModelCreator() {
        User storage creator = registeredUsers[_msgSender()];
        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (creator.isCreator == false) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        _;
    }

    modifier onlyBadgeModelOwnerCreator(uint256 badgeModelId) {
        User storage user = registeredUsers[_msgSender()];
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (bytes(user.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (user.isCreator == false) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (user.suspended == true) {
            revert TheBadge__onlyCreator_creatorIsSuspended();
        }
        if (_badgeModel.creator == address(0)) {
            revert TheBadge__updateBadgeModel_badgeModelNotFound();
        }
        if (_badgeModel.creator != _msgSender()) {
            revert TheBadge__updateBadgeModel_notBadgeModelOwner();
        }
        _;
    }

    modifier onlyBadgeModelMintable(uint256 badgeModelId) {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];
        BadgeModelController storage _badgeModelController = badgeModelControllers[_badgeModel.controllerName];
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);
        User storage creator = registeredUsers[_badgeModel.creator];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__requestBadge_badgeModelNotFound();
        }

        if (creator.suspended == true) {
            revert TheBadge__requestBadge_badgeModelIsSuspended();
        }

        if (_badgeModel.paused) {
            revert TheBadge__requestBadge_isPaused();
        }

        if (_badgeModelController.paused) {
            revert TheBadge__requestBadge_controllerIsPaused();
        }

        _;
    }

    modifier existingBadgeModelController(string memory controllerName) {
        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
        if (_badgeModelController.controller == address(0)) {
            revert TheBadge__controller_invalidController();
        }
        if (_badgeModelController.initialized == false) {
            revert TheBadge__controller_invalidController();
        }
        if (_badgeModelController.paused) {
            revert TheBadge__controller_controllerIsPaused();
        }
        _;
    }

    function initialize(address admin, address _feeCollector) public initializer {
        __Ownable_init();
        feeCollector = _feeCollector;
        registerUserProtocolFee = uint256(0);
        createBadgeModelProtocolFee = uint256(0);
        mintBadgeProtocolDefaultFeeInBps = uint256(1000); // in bps (= 10%)
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        emit LibTheBadge.Initialize(admin);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    function getUser(address userAddress) external view returns (User memory) {
        return registeredUsers[userAddress];
    }

    function getBadgeModelController(string memory controllerName) external view returns (BadgeModelController memory) {
        return badgeModelControllers[controllerName];
    }

    function getBadgeModel(uint256 badgeModelId) external view returns (BadgeModel memory) {
        return badgeModels[badgeModelId];
    }

    function getBadge(uint256 badgeId) external view returns (Badge memory) {
        return badges[badgeId];
    }

    function getCurrentBadgeModelsIdCounter() external view returns (uint256) {
        return badgeModelIdsCounter.current();
    }

    function getCurrentBadgeIdCounter() external view returns (uint256) {
        return badgeIdsCounter.current();
    }

    function getUserMintedBadgesByBadgeModel(
        uint256 badgeModelId,
        address userAddress
    ) external view returns (uint256[] memory) {
        return userMintedBadgesByBadgeModel[badgeModelId][userAddress];
    }

    /**
     * =========================
     * Setters
     * =========================
     */
    // TODO refactor to store updater role
    function createUser(address userAddress, User memory newUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
        User storage user = registeredUsers[userAddress];
        if (bytes(user.metadata).length != 0) {
            revert TheBadge__registerUser_alreadyRegistered();
        }
        registeredUsers[userAddress] = newUser;

        emit LibTheBadgeUsers.UpdatedUser(userAddress, user.metadata, user.suspended, user.isCreator, false);
    }

    // todo refactor with modifier to check that the user actually exists
    function updateUser(address userAddress, User memory updatedUser) external onlyRole(DEFAULT_ADMIN_ROLE) {
        User storage _user = registeredUsers[userAddress];
        if (bytes(_user.metadata).length == 0) {
            revert TheBadge__updateUser_notFound();
        }
        registeredUsers[userAddress] = updatedUser;

        emit LibTheBadgeUsers.UpdatedUser(
            userAddress,
            updatedUser.metadata,
            updatedUser.suspended,
            updatedUser.isCreator,
            false
        );
    }

    // TODO refactor to store updater role & validate that
    function addBadgeModelController(
        string memory controllerName,
        BadgeModelController memory badgeModelController
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
        if (_badgeModelController.controller != address(0)) {
            revert TheBadge__addBadgeModelController_alreadySet();
        }
        badgeModelControllers[controllerName] = badgeModelController;

        emit LibTheBadgeModels.BadgeModelControllerAdded(controllerName, badgeModelController.controller);
    }

    // TODO refactor to store updater role & validate that
    function addBadgeModel(BadgeModel memory badgeModel, string memory metadata) external onlyRole(DEFAULT_ADMIN_ROLE) {
        badgeModels[badgeModelIdsCounter.current()] = badgeModel;

        emit LibTheBadgeModels.BadgeModelCreated(badgeModelIdsCounter.current(), metadata);
        badgeModelIdsCounter.increment();
    }

    function updateBadgeModel(
        uint256 badgeModelId,
        BadgeModel memory badgeModel
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModel memory _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel = badgeModel;
        emit LibTheBadgeModels.BadgeModelUpdated(badgeModelId);
    }

    function addBadge(uint256 badgeId, Badge memory badge) external onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 _badgeModelId = badge.badgeModelId;
        address _account = badge.account;
        badges[badgeId] = badge;
        userMintedBadgesByBadgeModel[_badgeModelId][_account].push(badgeId);
        badgeIdsCounter.increment();
    }

    /*
     * @notice Updates the value of the protocol: _mintBadgeDefaultFee
     * @param _mintBadgeDefaultFee the default fee that TheBadge protocol charges for each mint (in bps)
     */
    function updateMintBadgeDefaultProtocolFee(uint256 _mintBadgeDefaultFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadgeProtocolDefaultFeeInBps = _mintBadgeDefaultFee;
        emit LibTheBadge.ProtocolSettingsUpdated();
    }

    /*
     * @notice Updates the value of the protocol: _createBadgeModelValue
     * @param _createBadgeModelValue the default fee that TheBadge protocol charges for each badge model creation (in bps)
     */
    function updateCreateBadgeModelProtocolFee(uint256 _createBadgeModelValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        createBadgeModelProtocolFee = _createBadgeModelValue;
        emit TheBadgeStore.ProtocolSettingsUpdated();
    }

    /*
     * @notice Updates the value of the protocol: _registerCreatorValue
     * @param _registerCreatorValue the default fee that TheBadge protocol charges for each user registration (in bps)
     */
    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        registerUserProtocolFee = _registerCreatorValue;
        emit TheBadgeStore.ProtocolSettingsUpdated();
    }

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
