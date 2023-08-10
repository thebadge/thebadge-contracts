// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./TheBadgeRoles.sol";
import "../../interfaces/IBadgeModelController.sol";

// TODO: Maybe we can use abstract classes to type the store
contract TheBadgeStore is TheBadgeRoles {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal badgeModelIdsCounter;
    CountersUpgradeable.Counter internal badgeIdsCounter;

    // TODO: does this var makes sense? it was thought to define a min value to mint a badge.
    // For example, if the badge is going to have a cost (it can be free) it has to be bigger than this variable.
    // badgeModel1 = mint cost is 4 because minBadgeMintValue is 4.
    // uint256 public minBadgeMintValue;
    uint256 public registerCreatorProtocolFee;
    uint256 public createBadgeModelProtocolFee;
    uint256 public mintBadgeProtocolDefaultFeeInBps;
    address public feeCollector;

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param metadata information related with the creator.
     * @param isVerified if it was verified by TheBadge.
     */
    struct Creator {
        string metadata;
        bool suspended; // If true, the creator is not allowed to do any actions and their badges are not minteable anymore.
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
    }

    /**
     * @param controller the smart contract that controls a badge model.
     * @param paused if the controller is paused, no operations can be done
     */
    struct BadgeModelController {
        address controller;
        bool paused;
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
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
    }

    struct Badge {
        uint256 badgeModelId;
        address account;
        uint256 dueDate;
        bool initialized; // When the struct is created its true, if the struct was never initialized, its false, used in validations
    }

    enum PaymentType {
        ProtocolFee,
        CreatorFee
    }

    mapping(address => Creator) public creators;
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
    event CreatorRegistered(address indexed creator, string metadata);
    event UpdatedCreatorMetadata(address indexed creator, string metadata);
    event SuspendedCreator(address indexed creator, bool suspended);
    event RemovedCreator(address indexed creator, bool deleted);
    event BadgeModelCreated(uint256 indexed badgeModelId, string metadata);
    event BadgeModelUpdated(uint256 indexed badgeModelId);
    event PaymentMade(
        address indexed recipient,
        uint256 amount,
        PaymentType indexed paymentType,
        uint256 indexed badgeModelId
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

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyCreator_creatorIsSuspended();

    error TheBadge__registerCreator_wrongValue();
    error TheBadge__registerCreator_alreadyRegistered();
    error TheBadge__setBadgeModelController_emptyName();
    error TheBadge__setBadgeModelController_notFound();
    error TheBadge__setBadgeModelController_alreadySet();
    error TheBadge__setControllerStatus_notFound();
    error TheBadge__createBadgeModel_invalidController();
    error TheBadge__createBadgeModel_controllerIsPaused();
    error TheBadge__createBadgeModel_wrongValue();
    error TheBadge__updateBadgeModel_notBadgeModelOwner();
    error TheBadge__updateBadgeModel_badgeModelNotFound();
    error TheBadge__badgeModel_badgeModelNotFound();
    error TheBadge__updateCreator_notFound();

    error TheBadge__SBT();
    error TheBadge__requestBadge_badgeModelNotFound();
    error TheBadge__requestBadge_badgeModelIsSuspended();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_controllerIsPaused();

    error TheBadge__method_not_supported();

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyRegisteredBadgeModelCreator() {
        Creator storage creator = creators[_msgSender()];
        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        _;
    }

    modifier onlyBadgeModelOwnerCreator(uint256 badgeModelId) {
        Creator storage creator = creators[_msgSender()];
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (creator.suspended == true) {
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
        Creator storage creator = creators[_badgeModel.creator];

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

    receive() external payable {}
}
