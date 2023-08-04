// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./TheBadgeRoles.sol";
import "../../interfaces/IBadgeController.sol";

contract TheBadgeStore is TheBadgeRoles {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal badgeModelIds;
    uint256 public registerCreatorValue;
    uint256 public mintBadgeDefaultFee; // in bps
    // TODO: does this var makes sense? it was thought to define a min value to mint a badge.
    // For example, if the badge is going to have a cost (it can be free) it has to be bigger than this variable.
    // badgeModel1 = mint cost is 4 because minBadgeMintValue is 4.
    // uint256 public minBadgeMintValue;
    uint256 public createBadgeModelValue;
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
    }

    /**
     * @param controller the smart contract that controls a badge model.
     * @param paused if the controller is paused, no operations can be done
     */
    struct BadgeModelController {
        address controller;
        bool paused;
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
        uint256 mintCreatorFee;
        uint256 validFor;
        uint256 mintProtocolFee; // in bps. It is taken from mintCreatorFee
    }

    struct Badge {
        uint256 badgeModelId;
        address account;
        uint256 dueDate;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    mapping(address => Creator) public creators;
    mapping(string => BadgeModelController) public badgeModelController;
    mapping(uint256 => BadgeModel) public badgeModel;
    mapping(uint256 => Badge) public badge;
    mapping(uint256 => mapping(address => uint256[])) public badgeModelsByAccount;

    /**
     * =========================
     * Events
     * =========================
     */
    event CreatorRegistered(address indexed creator, string metadata);
    event CreatorUpdated(address indexed creator, string metadata);
    event BadgeModelCreated(uint256 indexed badgeModelId, string metadata);
    // TODO: Check if this is needed or can be removed
    event BadgeRequested(uint256 indexed badgeModelID, uint256 indexed badgeID, address indexed wallet);

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyController_senderIsNotTheController();

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
    error TheBadge__updateBadgeModelFee_badgeModelNotFound();
    error TheBadge__updateCreator_notFound();

    error TheBadge__SBT();
    error TheBadge__requestBadge_badgeModelNotFound();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_controllerIsPaused();

    error TheBadge__method_not_supported();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyBadgeModelCreator() {
        Creator storage creator = creators[msg.sender];
        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        _;
    }

    modifier onlyController(address sender, uint256 badgeId) {
        BadgeModel storage _badgeModel = badgeModel[badgeId];
        if (sender != badgeModelController[_badgeModel.controllerName].controller) {
            revert TheBadge__onlyController_senderIsNotTheController();
        }
        _;
    }

    /**
     * =========================
     * Methods
     * =========================
     */

    // TODO: check if this is secure
    /*
     * @notice Increments the amount of badgeModelsIds in 1, should be called only by internal contracts.
     */
    function updateBadgeModelsTotalSupply() internal {
        badgeModelIds.increment();
    }

    /*
     * @notice Returns the amount of badgeModelIds
     */
    function badgeModelsTotalSupply() internal view returns (uint256) {
        return badgeModelIds.current();
    }

    // TODO: suspend badgeModel. I think we don't as we might want to use a Kleros list to handle the creations of lists.

    receive() external payable {}
}
