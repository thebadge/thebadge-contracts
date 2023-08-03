// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./TheBadgeRoles.sol";
import "./interfaces/IBadgeController.sol";

contract TheBadgeLogic is TheBadgeRoles {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private badgeModelIds;
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
     * @param controller the smart contract that controls a badge type.
     * @param paused if the controller is paused, no operations can be done
     */
    struct BadgeModelController {
        address controller;
        bool paused;
    }

    /**
     * Struct to use as arg to create a badge type
     */
    struct CreateBadgeModel {
        string metadata;
        string controllerName;
        uint256 mintCreatorFee;
        uint256 validFor;
    }

    /**
     * Struct to store generic information of a badge type.
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

    /**
     * @notice Calculate percentage using basis points
     */
    function calculateFee(uint256 amount, uint256 bps) internal pure returns (uint256) {
        require((amount * bps) >= 10_000);
        return (amount * bps) / 10_000;
    }

    function updateProtocolValues(
        uint256 _mintBadgeDefaultFee,
        uint256 _createBadgeModelValue,
        uint256 _registerCreatorValue
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadgeDefaultFee = _mintBadgeDefaultFee;
        createBadgeModelValue = _createBadgeModelValue;
        registerCreatorValue = _registerCreatorValue;
    }

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
     * @notice pause/unpause controller
     */
    function setControllerStatus(string memory controllerName, bool isPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModelController storage _badgeModelController = badgeModelController[controllerName];

        if (_badgeModelController.controller == address(0)) {
            revert TheBadge__setControllerStatus_notFound();
        }

        _badgeModelController.paused = isPaused;
    }

    /**
     * @notice Register a new badge type creator
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

    // TODO: suspend/remove creator
    // TODO: suspend/remove badgeModel creator

    /**
     * @notice Creates a badge type that will allow users to mint badges of this type.
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

        badgeModelIds.increment();
    }

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

    // TODO: suspend badgeModel. I think we don't as we might want to use a Kleros list to handle the creations of lists.

    function updateBadgeModelFee(uint256 badgeModelId, uint256 feeInBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__updateBadgeModelFee_badgeModelNotFound();
        }

        _badgeModel.mintProtocolFee = feeInBps;
    }

    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];
        IBadgeController controller = IBadgeController(badgeModelController[_badgeModel.controllerName].controller);

        return controller.mintValue(badgeModelId) + _badgeModel.mintCreatorFee;
    }

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

        return balance;
    }

    receive() external payable {}
}
