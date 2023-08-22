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

    /*
     * @notice Creates a badge model that will allow users to mint badges of this model.
     * @param CreateBadgeModel struct that contains: metadata; controllerName; mintCreatorFee and validFor
     * @param data evidence metadata for the badge model controller
     */
    function createBadgeModel(
        CreateBadgeModel memory args,
        bytes memory data
    ) public payable onlyRegisteredUser(_msgSender()) existingBadgeModelController(args.controllerName) {
        // check values
        if (msg.value < createBadgeModelProtocolFee) {
            revert TheBadge__createBadgeModel_wrongValue();
        }

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

        User storage user = registeredUsers[_msgSender()];
        if (user.isCreator == false) {
            user.isCreator = true;
            emit CreatorRegistered(_msgSender());
        }

        emit BadgeModelCreated(badgeModelIdsCounter.current(), args.metadata);
        // TODO: According to the type of controller, modify the data.admin value
        BadgeModelController storage _badgeModelController = badgeModelControllers[args.controllerName];
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

        User storage creator = registeredUsers[_badgeModel.creator];
        if (creator.suspended == true) {
            return true;
        }

        return false;
    }
}
