// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
/**
 * =========================
 * Contains all the logic related to badge models (but not badges)
 * =========================
 */

import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { LibTheBadgeModels } from "../libraries/LibTheBadgeModels.sol";
import { LibTheBadgeUsers } from "../libraries/LibTheBadgeUsers.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";
import { TheBadgeStore } from "./TheBadgeStore.sol";
import { ITheBadgeModels } from "../../interfaces/ITheBadgeModels.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { TheBadgeUsers } from "./TheBadgeUsers.sol";

contract TheBadgeModels is TheBadgeRoles, ITheBadgeModels, OwnableUpgradeable {
    TheBadgeStore public _badgeStore;
    TheBadgeUsers public _theBadgeUsers;
    // Allows to use current() and increment() for badgeModelIds or badgeIds
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * =========================
     * Events
     * =========================
     */
    event BadgeModelCreated(uint256 indexed badgeModelId, string metadata);
    event BadgeModelUpdated(uint256 indexed badgeModelId);
    event BadgeModelControllerAdded(string indexed controllerName, address indexed controllerAddress);

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyRegisteredUser(address _user) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_user);
        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__onlyUser_userNotFound();
        }
        _;
    }

    modifier existingBadgeModelController(string memory controllerName) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        if (_badgeModelController.controller == address(0)) {
            revert LibTheBadge.TheBadge__controller_invalidController();
        }
        if (_badgeModelController.initialized == false) {
            revert LibTheBadge.TheBadge__controller_invalidController();
        }
        if (_badgeModelController.paused) {
            revert LibTheBadge.TheBadge__controller_controllerIsPaused();
        }
        _;
    }

    modifier onlyBadgeModelOwnerCreator(uint256 badgeModelId, address _user) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_user);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (user.isCreator == false) {
            revert LibTheBadgeUsers.TheBadge__onlyCreator_senderIsNotACreator();
        }
        if (user.suspended == true) {
            revert LibTheBadgeUsers.TheBadge__onlyCreator_creatorIsSuspended();
        }
        if (_badgeModel.creator == address(0)) {
            revert LibTheBadgeModels.TheBadge__updateBadgeModel_badgeModelNotFound();
        }
        if (_badgeModel.creator != _user) {
            revert LibTheBadgeModels.TheBadge__updateBadgeModel_notBadgeModelOwner();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address badgeStore, address badgeUsers) public initializer {
        __Ownable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _badgeStore = TheBadgeStore(payable(badgeStore));
        _theBadgeUsers = TheBadgeUsers(payable(badgeUsers));
    }

    /**
     * @notice Adds a badge model controller to the supported list of controllers
     * @param controllerName - name of the controller (for instance: Kleros)
     * @param controllerAddress - address of the controller
     */
    function addBadgeModelController(
        string memory controllerName,
        address controllerAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );

        if (bytes(controllerName).length == 0) {
            revert LibTheBadgeModels.TheBadge__addBadgeModelController_emptyName();
        }

        if (controllerAddress == address(0)) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        if (_badgeModelController.controller != address(0)) {
            revert LibTheBadgeModels.TheBadge__addBadgeModelController_alreadySet();
        }

        _badgeModelController.controller = controllerAddress;
        _badgeModelController.initialized = true;
        _badgeModelController.paused = false;

        _badgeStore.addBadgeModelController(controllerName, _badgeModelController);
        emit BadgeModelControllerAdded(controllerName, controllerAddress);
    }

    /*
     * @notice Creates a badge model that will allow users to mint badges of this model.
     * @param CreateBadgeModel struct that contains: metadata; controllerName; mintCreatorFee and validFor
     * @param data evidence metadata for the badge model controller
     */
    function createBadgeModel(
        TheBadgeStore.CreateBadgeModel memory args,
        bytes memory data
    ) public payable onlyRegisteredUser(_msgSender()) existingBadgeModelController(args.controllerName) {
        uint256 createBadgeModelProtocolFee = _badgeStore.createBadgeModelProtocolFee();
        // check values
        if (msg.value < createBadgeModelProtocolFee) {
            revert LibTheBadgeModels.TheBadge__createBadgeModel_wrongValue();
        }

        // move fees to collector
        address feeCollector = _badgeStore.feeCollector();
        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        uint256 mintBadgeProtocolDefaultFeeInBps = _badgeStore.mintBadgeProtocolDefaultFeeInBps();
        TheBadgeStore.BadgeModel memory _newBadgeModel = TheBadgeStore.BadgeModel(
            _msgSender(),
            args.controllerName,
            false,
            args.mintCreatorFee,
            args.validFor,
            mintBadgeProtocolDefaultFeeInBps,
            true,
            "v1.0.0"
        );

        uint256 currentBadgeModelId = _badgeStore.getCurrentBadgeModelsIdCounter();
        _badgeStore.addBadgeModel(_newBadgeModel);
        emit BadgeModelCreated(currentBadgeModelId, args.metadata);
        TheBadgeStore.User memory user = _badgeStore.getUser(_msgSender());
        if (user.isCreator == false) {
            _theBadgeUsers.makeUserCreator(_msgSender());
        }
        // TODO: According to the type of controller, modify the data.admin value
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            args.controllerName
        );
        IBadgeModelController(_badgeModelController.controller).createBadgeModel(currentBadgeModelId, data);
    }

    /*
     * @notice Updates a badge model
     * @param badgeModelId
     * @param mintCreatorFee fee that the creator charges for each mint
     * @param validFor is the badge has expiration time
     * @param paused if the creator wants to stop the minting of this badges
     */
    function updateBadgeModel(
        uint256 badgeModelId,
        uint256 mintCreatorFee,
        bool paused
    ) public onlyBadgeModelOwnerCreator(badgeModelId, _msgSender()) {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.mintCreatorFee = mintCreatorFee;
        _badgeModel.paused = paused;

        _badgeStore.updateBadgeModel(badgeModelId, _badgeModel);
        emit BadgeModelUpdated(badgeModelId);
    }

    function suspendBadgeModel() public view onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: suspend badgeModel. I think we don't as we might want to use a Kleros list to handle the creations of lists.
        // TODO remove the view modifier and implement
        revert LibTheBadgeModels.TheBadge__method_not_supported();
    }

    /*
     * @notice Updates the badge model PROTOCOL fee
     * @param badgeModelId
     * @param feeInBps fee that the protocol will charge for this badge
     */
    function updateBadgeModelProtocolFee(uint256 badgeModelId, uint256 feeInBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.mintProtocolFee = feeInBps;
        _badgeStore.updateBadgeModel(badgeModelId, _badgeModel);
        emit BadgeModelUpdated(badgeModelId);
    }

    /*
     * @notice Given a badgeModelId, returns true if the badgeModel is suspended (this means that his creator is also suspended), otherwise returns false
     * @param badgeModelId the id of the badgeModel
     */
    function isBadgeModelSuspended(uint256 badgeModelId) public view returns (bool) {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadgeModels.TheBadge__badgeModel_badgeModelNotFound();
        }

        TheBadgeStore.User memory creator = _badgeStore.getUser(_badgeModel.creator);
        if (creator.suspended == true) {
            return true;
        }

        return false;
    }

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
