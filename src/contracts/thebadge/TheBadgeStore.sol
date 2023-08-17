// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";

// TODO: Maybe we can use abstract classes to type the store
contract TheBadgeStore is TheBadgeRoles {
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

    enum PaymentType {
        ProtocolFee,
        CreatorMintFee,
        UserRegistrationFee,
        UserVerificationFee
    }

    mapping(address => User) public registeredUsers;
    mapping(string => BadgeModelController) public badgeModelControllers;
    mapping(uint256 => BadgeModel) public badgeModels;
    mapping(uint256 => Badge) public badges;
    mapping(uint256 => mapping(address => uint256[])) public badgeModelsByAccount;

    /**
     * =========================
     * Events
     * =========================
     */
    event Initialize(address indexed admin, address indexed minter);
    event UserRegistered(address indexed creator, string metadata);
    event CreatorRegistered(address indexed creator);
    event UserVerificationRequested(address indexed user, string metadata, string controllerName);
    event UserVerificationExecuted(address indexed user, string controllerName, bool verify);
    event UpdatedUserMetadata(address indexed creator, string metadata);
    event SuspendedUser(address indexed creator, bool suspended);
    event RemovedUser(address indexed creator, bool deleted);
    event BadgeModelCreated(uint256 indexed badgeModelId, string metadata);
    event BadgeModelUpdated(uint256 indexed badgeModelId);
    event PaymentMade(
        address indexed recipient,
        uint256 amount,
        PaymentType indexed paymentType,
        uint256 indexed badgeModelId
    );

    event UserVerificationPaymentMade(
        address indexed recipient,
        uint256 amount,
        PaymentType indexed paymentType,
        string controllerName,
        address creatorAddress
    );

    event BadgeModelProtocolFeeUpdated(uint256 indexed badgeModelId, uint256 newAmountInBps);
    event ProtocolSettingsUpdated();
    event BadgeRequested(
        uint256 indexed badgeModelID,
        uint256 indexed badgeID,
        address indexed recipient,
        address controller,
        uint256 controllerBadgeId
    );
    event BadgeModelControllerAdded(string indexed controllerName, address indexed controllerAddress);

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__onlyUser_userNotFound();
    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyCreator_creatorIsSuspended();

    error TheBadge__registerUser_wrongValue();
    error TheBadge__registerUser_alreadyRegistered();
    error TheBadge__addBadgeModelController_emptyName();
    error TheBadge__addBadgeModelController_notFound();
    error TheBadge__addBadgeModelController_alreadySet();
    error TheBadge__setControllerStatus_notFound();
    error TheBadge__controller_invalidController();
    error TheBadge__controller_controllerIsPaused();
    error TheBadge__createBadgeModel_wrongValue();
    error TheBadge__updateBadgeModel_notBadgeModelOwner();
    error TheBadge__updateBadgeModel_badgeModelNotFound();
    error TheBadge__badgeModel_badgeModelNotFound();
    error TheBadge__updateUser_notFound();

    error TheBadge__verifyUser_wrongValue();
    error TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();

    error TheBadge__SBT();
    error TheBadge__requestBadge_badgeModelNotFound();
    error TheBadge__requestBadge_badgeModelIsSuspended();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_controllerIsPaused();
    error TheBadge__requestBadge_badgeNotFound();
    error TheBadge__requestBadge_badgeNotClaimable();

    error TheBadge__method_not_supported();

    error TheBadge__mint_protocolFeesPaymentFailed();
    error TheBadge__mint_creatorFeesPaymentFailed();

    error TheBadge__calculateFee_protocolFeesInvalidValues();

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

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
