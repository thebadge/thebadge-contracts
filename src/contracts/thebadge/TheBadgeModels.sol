pragma solidity ^0.8.17;
/**
 * =========================
 * Contains all the logic related to badge models (but not badges)
 * =========================
 */

import "../../interfaces/IBadgeController.sol";
import "./TheBadgeRoles.sol";
import "./TheBadgeStore.sol";

contract TheBadgeModels is TheBadgeRoles, TheBadgeStore {
    // Allows to use current() and increment() for badgeModelIds or badgeIds
    using CountersUpgradeable for CountersUpgradeable.Counter;
    /**
     * @notice Sets the controller for the given badgeModel
     * @param controllerName - name of the controller (for instance: Kleros)
     * @param controllerAddress - address of the controller
     */
    function setBadgeModelController(
        string memory controllerName,
        address controllerAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModelController storage _badgeModelController = badgeModelController[controllerName];

        if (bytes(controllerName).length == 0) {
            revert TheBadge__setBadgeModelController_emptyName();
        }

        if (controllerAddress == address(0)) {
            revert TheBadge__setBadgeModelController_notFound();
        }

        if (_badgeModelController.controller != address(0)) {
            revert TheBadge__setBadgeModelController_alreadySet();
        }

        badgeModelController[controllerName] = BadgeModelController(controllerAddress, false);
    }

    /**
     * @notice Register a new badge model creator
     * @param _metadata IPFS url
     */
    function registerBadgeModelCreator(string memory _metadata) public payable {
        if (msg.value != registerCreatorValue) {
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

        emit CreatorUpdated(_creator, _metadata);
    }

    function suspendBadgeModelCreator() public view onlyRole(DEFAULT_ADMIN_ROLE) {
        // TODO remove the view modifier and implement
        revert TheBadge__method_not_supported();
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
    function createBadgeModel(CreateBadgeModel memory args, bytes memory data) public payable onlyBadgeModelCreator {
        // check values
        if (msg.value != createBadgeModelValue) {
            revert TheBadge__createBadgeModel_wrongValue();
        }

        // verify valid controller
        BadgeModelController storage _badgeModelController = badgeModelController[args.controllerName];
        if (_badgeModelController.controller == address(0)) {
            revert TheBadge__createBadgeModel_invalidController();
        }
        if (_badgeModelController.paused) {
            revert TheBadge__createBadgeModel_controllerIsPaused();
        }

        // move fees to collector
        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        badgeModel[badgeModelIds.current()] = BadgeModel(
            _msgSender(),
            args.controllerName,
            false,
            args.mintCreatorFee,
            args.validFor,
            mintBadgeDefaultFee
        );

        emit BadgeModelCreated(badgeModelIds.current(), args.metadata);
        IBadgeController(_badgeModelController.controller).createBadgeModel(badgeModelIds.current(), data);
        // TODO emit BadgeRequested(badgeModelID, badgeID, wallet)?

        badgeModelIds.increment();
    }

    /*
     * @notice Updates a badge model
     * @param badgeModelId
     * @param mintCreatorFee fee that the creator charges for each mint
     * @param validFor is the badge has expiration time
     * @param paused if the creator wants to stop the minting of this badges
     */
    // TODO: add the onlyOwner role
    function updateBadgeModel(uint256 badgeModelId, uint256 mintCreatorFee, uint256 validFor, bool paused) public {
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__updateBadgeModel_badgeModelNotFound();
        }

        if (_msgSender() != _badgeModel.creator) {
            revert TheBadge__updateBadgeModel_notBadgeModelOwner();
        }

        _badgeModel.mintCreatorFee = mintCreatorFee;
        _badgeModel.validFor = validFor;
        _badgeModel.paused = paused;
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
    function updateBadgeModelFee(uint256 badgeModelId, uint256 feeInBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__updateBadgeModelFee_badgeModelNotFound();
        }

        _badgeModel.mintProtocolFee = feeInBps;
    }

    /*
     * @notice given an account address and a badgeModelId returns 1 if the users owns the badge or if it's not expired, otherwise returns 0
     * @param account user address
     * @param badgeModelId ID of the badgeModel
     */
    function balanceOfBadgeModel(address account, uint256 badgeModelId) public view returns (uint256) {
        if (badgeModelsByAccount[badgeModelId][account].length == 0) {
            return 0;
        }

        BadgeModel memory _badgeModel = badgeModel[badgeModelId];
        IBadgeController controller = IBadgeController(badgeModelController[_badgeModel.controllerName].controller);

        uint256 balance = 0;
        for (uint i = 0; i < badgeModelsByAccount[badgeModelId][account].length; i++) {
            if (controller.isAssetActive(badgeModelsByAccount[badgeModelId][account][i])) {
                balance++;
            }
        }
        // TODO: this should check if the badge didn't expired?

        return balance;
    }

    /*
     * @notice given badgeModelId returns the cost of minting that badge (controller minting fee + mintCreatorFee)
     * @param badgeModelId
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];
        IBadgeController controller = IBadgeController(badgeModelController[_badgeModel.controllerName].controller);

        return controller.mintValue(badgeModelId) + _badgeModel.mintCreatorFee;
    }
}
