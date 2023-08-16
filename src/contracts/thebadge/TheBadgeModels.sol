// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
/**
 * =========================
 * Contains all the logic related to badge models (but not badges)
 * =========================
 */

import "../../interfaces/IBadgeModelController.sol" as BadgeModelController;
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { TheBadgeStore } from "./TheBadgeStore.sol";
import { ITheBadgeModels } from "../../interfaces/ITheBadgeModels.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";

contract TheBadgeModels is TheBadgeRoles, TheBadgeStore, ITheBadgeModels {
    // Allows to use current() and increment() for badgeModelIds or badgeIds
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /**
     * @notice Adds a badge model controller to the supported list of controllers
     * @param controllerName - name of the controller (for instance: Kleros)
     * @param controllerAddress - address of the controller
     */
    function addBadgeModelController(
        string memory controllerName,
        address controllerAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];

        if (bytes(controllerName).length == 0) {
            revert TheBadge__addBadgeModelController_emptyName();
        }

        if (controllerAddress == address(0)) {
            revert TheBadge__addBadgeModelController_notFound();
        }

        if (_badgeModelController.controller != address(0)) {
            revert TheBadge__addBadgeModelController_alreadySet();
        }

        badgeModelControllers[controllerName] = BadgeModelController(controllerAddress, false, true);
        emit BadgeModelControllerAdded(controllerName, controllerAddress);
    }

    /**
     * @notice Register a new badge model creator
     * @param _metadata IPFS url
     */
    function registerBadgeModelCreator(string memory _metadata) public payable {
        if (msg.value != registerCreatorProtocolFee) {
            revert TheBadge__registerCreator_wrongValue();
        }

        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        Creator storage creator = creators[_msgSender()];
        if (bytes(creator.metadata).length != 0) {
            revert TheBadge__registerCreator_alreadyRegistered();
        }

        creator.metadata = _metadata;
        creator.initialized = true;
        creator.suspended = false;
        creator.verified = false;

        emit CreatorRegistered(_msgSender(), creator.metadata);
    }

    /**
     * @notice Given a creator and new metadata, updates the metadata of the badge model creator
     * @param _creator creator address
     * @param _metadata IPFS url
     */
    function updateBadgeModelCreator(address _creator, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Creator storage creator = creators[_creator];

        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__updateCreator_notFound();
        }

        if (bytes(_metadata).length > 0) {
            creator.metadata = _metadata;
        }

        emit UpdatedCreatorMetadata(_creator, _metadata);
    }

    function suspendBadgeModelCreator(address _creator, bool suspended) public onlyRole(PAUSER_ROLE) {
        Creator storage creator = creators[_creator];

        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__updateCreator_notFound();
        }

        creator.suspended = suspended;
        emit SuspendedCreator(_creator, suspended);
    }

    function removeBadgeModelCreator() public view onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO remove the view modifier and implement
        revert TheBadge__method_not_supported();
    }

    /*
     * @notice Creates a badge model that will allow users to mint badges of this model.
     * @param CreateBadgeModel struct that contains: metadata; controllerName; mintCreatorFee and validFor
     * @param data evidence metadata for the badge model controller
     */
    function createBadgeModel(
        CreateBadgeModel memory args,
        bytes memory data
    ) public payable onlyRegisteredBadgeModelCreator {
        // check values
        if (msg.value < createBadgeModelProtocolFee) {
            revert TheBadge__createBadgeModel_wrongValue();
        }

        // Get valid controller
        BadgeModelController storage _badgeModelController = getControllerFromBadgeControllerName(args.controllerName);

        // move fees to collector
        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        badgeModels[badgeModelIdsCounter.current()] = BadgeModel(
            _msgSender(),
            args.controllerName,
            false,
            args.mintCreatorFee,
            args.validFor,
            mintBadgeProtocolDefaultFeeInBps,
            true,
            "v1.0.0"
        );

        emit BadgeModelCreated(badgeModelIdsCounter.current(), args.metadata);
        // TODO: According to the type of controller, modify the data.admin value
        IBadgeModelController(_badgeModelController.controller).createBadgeModel(badgeModelIdsCounter.current(), data);
        badgeModelIdsCounter.increment();
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
    ) public onlyBadgeModelOwnerCreator(badgeModelId) {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.mintCreatorFee = mintCreatorFee;
        _badgeModel.paused = paused;
        emit BadgeModelUpdated(badgeModelId);
    }

    function suspendBadgeModel() public view onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO: suspend badgeModel. I think we don't as we might want to use a Kleros list to handle the creations of lists.
        // TODO remove the view modifier and implement
        revert TheBadge__method_not_supported();
    }

    /*
     * @notice Updates the badge model PROTOCOL fee
     * @param badgeModelId
     * @param feeInBps fee that the protocol will charge for this badge
     */
    function updateBadgeModelProtocolFee(uint256 badgeModelId, uint256 feeInBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__badgeModel_badgeModelNotFound();
        }

        _badgeModel.mintProtocolFee = feeInBps;
        emit BadgeModelProtocolFeeUpdated(badgeModelId, feeInBps);
    }

    /*
     * @notice given badgeModelId returns the cost of minting that badge (controller minting fee + mintCreatorFee)
     * @param badgeModelId the id of the badgeModel
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__badgeModel_badgeModelNotFound();
        }

        IBadgeModelController controller = IBadgeModelController(
            badgeModelControllers[_badgeModel.controllerName].controller
        );
        return controller.mintValue(badgeModelId) + _badgeModel.mintCreatorFee;
    }

    /*
     * @notice Given a badgeModelId, returns true if the badgeModel is suspended (this means that his creator is also suspended), otherwise returns false
     * @param badgeModelId the id of the badgeModel
     */
    function isBadgeModelSuspended(uint256 badgeModelId) public view returns (bool) {
        BadgeModel storage _badgeModel = badgeModels[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__badgeModel_badgeModelNotFound();
        }

        Creator storage creator = creators[_badgeModel.creator];
        if (creator.suspended == true) {
            return true;
        }

        return false;
    }

    /**
     * @notice Given a controller name, returns the controller if exists
     * @param controllerName the id badgeModelController
     */
    function getControllerFromBadgeControllerName(string controllerName) internal view returns (BadgeModelController) {
        // verify valid controller
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

        return _badgeModelController;
    }
}
