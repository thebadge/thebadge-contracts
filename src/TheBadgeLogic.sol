// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./TheBadgeRoles.sol";
import "./interfaces/IBadgeController.sol";

contract TheBadgeLogic is TheBadgeRoles {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private badgeTypeIds;
    uint256 public registerCreatorValue;
    uint256 public mintBadgeDefaultFee; // in bps
    // TODO: does this var makes sense? it was thought to define a min value to mint a badge.
    // For example, if the badge is going to have a cost (it can be free) it has to be bigger than this variable.
    // badgeType1 = mint cost is 4 because minBadgeMintValue is 4.
    // uint256 public minBadgeMintValue;
    uint256 public createBadgeTypeValue;
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
    struct BadgeTypeController {
        address controller;
        bool paused;
    }

    /**
     * Struct to use as arg to create a badge type
     */
    struct CreateBadgeType {
        string metadata;
        string controllerName;
        uint256 mintCreatorFee;
        uint256 validFor;
    }

    /**
     * Struct to store generic information of a badge type.
     */
    struct BadgeType {
        address creator;
        string controllerName;
        bool paused;
        uint256 mintCreatorFee;
        uint256 validFor;
        uint256 mintProtocolFee; // in bps. It is taken from mintCreatorFee
    }

    /**
     * =========================
     * Store
     * =========================
     */

    mapping(address => Creator) public creators;
    /**
     * @notice badge types controllers
     */
    mapping(string => BadgeTypeController) public badgeTypeController;
    /**
     * @notice base information of a badge.
     * badgeId => BadgeType
     */
    mapping(uint256 => BadgeType) public badgeType;

    /**
     * =========================
     * Events
     * =========================
     */
    event CreatorRegistered(address indexed creator, string metadata);
    event CreatorUpdated(address indexed creator, string metadata);
    event BadgeTypeCreated(uint256 indexed badgeTypeID, string metadata);

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__onlyCreator_senderIsNotACreator();
    error TheBadge__onlyController_senderIsNotTheController();
    error TheBadge__registerCreator_wrongValue();
    error TheBadge__registerCreator_alreadyRegistered();
    error TheBadge__setBadgeTypeController_emptyName();
    error TheBadge__setBadgeTypeController_notFound();
    error TheBadge__setBadgeTypeController_alreadySet();
    error TheBadge__setControllerStatus_notFound();
    error TheBadge__createBadgeType_invalidController();
    error TheBadge__createBadgeType_controllerIsPaused();
    error TheBadge__createBadgeType_wrongValue();
    error TheBadge__updateBadgeType_notBadgeTypeOwner();
    error TheBadge__updateBadgeType_badgeTypeNotFound();
    error TheBadge__updateBadgeTypeFee_badgeTypeNotFound();
    error TheBadge__updateCreator_notFound();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyBadgeTypeCreator() {
        Creator storage creator = creators[msg.sender];
        if (bytes(creator.metadata).length == 0) {
            revert TheBadge__onlyCreator_senderIsNotACreator();
        }
        _;
    }

    modifier onlyController(address sender, uint256 badgeId) {
        BadgeType storage _badgeType = badgeType[badgeId];
        if (sender != badgeTypeController[_badgeType.controllerName].controller) {
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
        uint256 _createBadgeTypeValue,
        uint256 _registerCreatorValue
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadgeDefaultFee = _mintBadgeDefaultFee;
        createBadgeTypeValue = _createBadgeTypeValue;
        registerCreatorValue = _registerCreatorValue;
    }

    /**
     * @notice Sets the controller address for a badgeType.
     * Once set, can not be modified to avoid losing controller internal state.
     */
    function setBadgeTypeController(
        string memory controllerName,
        address controllerAddress
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeTypeController storage _badgeTypeController = badgeTypeController[controllerName];

        if (bytes(controllerName).length == 0) {
            revert TheBadge__setBadgeTypeController_emptyName();
        }

        if (controllerAddress == address(0)) {
            revert TheBadge__setBadgeTypeController_notFound();
        }

        if (_badgeTypeController.controller != address(0)) {
            revert TheBadge__setBadgeTypeController_alreadySet();
        }

        badgeTypeController[controllerName] = BadgeTypeController(controllerAddress, false);
    }

    /**
     * @notice pause/unpause controller
     */
    function setControllerStatus(string memory controllerName, bool isPaused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeTypeController storage _badgeTypeController = badgeTypeController[controllerName];

        if (_badgeTypeController.controller == address(0)) {
            revert TheBadge__setControllerStatus_notFound();
        }

        _badgeTypeController.paused = isPaused;
    }

    /**
     * @notice Register a new badge type creator
     * @param _metadata IPFS url
     */
    function registerBadgeTypeCreator(string memory _metadata) public payable {
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
     * @dev Allow to update some creator's attributes for the admin
     * @param _creator The creator address
     */
    function updateBadgeTypeCreator(address _creator, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
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
    // TODO: suspend/remove badgeType creator

    /**
     * @notice Creates a badge type that will allow users to mint badges of this type.
     */
    function createBadgeType(CreateBadgeType memory args, bytes memory data) public payable onlyBadgeTypeCreator {
        // check values
        if (msg.value != createBadgeTypeValue) {
            revert TheBadge__createBadgeType_wrongValue();
        }

        // verify valid controller
        BadgeTypeController storage _badgeTypeController = badgeTypeController[args.controllerName];
        if (_badgeTypeController.controller == address(0)) {
            revert TheBadge__createBadgeType_invalidController();
        }
        if (_badgeTypeController.paused) {
            revert TheBadge__createBadgeType_controllerIsPaused();
        }

        // move fees to collector
        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        badgeType[badgeTypeIds.current()] = BadgeType(
            _msgSender(),
            args.controllerName,
            false,
            args.mintCreatorFee,
            args.validFor,
            mintBadgeDefaultFee
        );

        emit BadgeTypeCreated(badgeTypeIds.current(), args.metadata);
        IBadgeController(_badgeTypeController.controller).createBadgeType(badgeTypeIds.current(), data);

        badgeTypeIds.increment();
    }

    /**
     * @notice Edit some attributes of a badgeType
     */
    function updateBadgeType(uint256 badgeTypeId, uint256 mintCreatorFee, uint256 validFor, bool paused) public {
        BadgeType storage _badgeType = badgeType[badgeTypeId];

        if (_badgeType.creator == address(0)) {
            revert TheBadge__updateBadgeType_badgeTypeNotFound();
        }

        if (_msgSender() != _badgeType.creator) {
            revert TheBadge__updateBadgeType_notBadgeTypeOwner();
        }

        _badgeType.mintCreatorFee = mintCreatorFee;
        _badgeType.validFor = validFor;
        _badgeType.paused = paused;
    }

    // TODO: suspend badgeType ?

    /**
     * @notice Allows the admin to modify the platform fee when a user mints a badge of a specific badgeType
     */
    function updateBadgeTypeFee(uint256 badgeTypeId, uint256 feeInBps) public onlyRole(DEFAULT_ADMIN_ROLE) {
        BadgeType storage _badgeType = badgeType[badgeTypeId];

        if (_badgeType.creator == address(0)) {
            revert TheBadge__updateBadgeTypeFee_badgeTypeNotFound();
        }

        _badgeType.mintProtocolFee = feeInBps;
    }

    /**
     * @notice returns the cost for minting a badge of a badgeType
     */
    function mintValue(uint256 badgeTypeId) public view returns (uint256) {
        BadgeType storage _badgeType = badgeType[badgeTypeId];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        return controller.mintValue(badgeTypeId) + _badgeType.mintCreatorFee;
    }

    receive() external payable {}
}
