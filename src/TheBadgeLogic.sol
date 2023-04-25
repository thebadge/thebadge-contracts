// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin-upgrade/contracts/utils/CountersUpgradeable.sol";
import "./TheBadgeRoles.sol";
import "./interfaces/IBadgeController.sol";

// TODO: rename emitter with creator
contract TheBadgeLogic is TheBadgeRoles {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private badgeTypeIds;
    uint256 public registerEmitterValue;
    uint256 public mintBadgeDefaultFee; // in bps
    uint256 public minBadgeMintValue;
    uint256 public createBadgeTypeValue;
    address public feeCollector;

    /**
     * =========================
     * Types
     * =========================
     */

    /**
     * @param metadata information related with the emitter.
     * @param isVerified if it was verified by TheBadge.
     */
    struct Emitter {
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
     * @param badgeType The type of the badge
     * @param mintCost The cost for minting a badge, it goes to the emitter.
     * @param mintFee The fee charged for The Badge to the mintCost.
     * @param validFor The time in seconds of how long the badge is valid. (cero for infinite)
     */
    struct CreateBadgeType {
        string metadata;
        string controllerName;
        uint256 mintCreatorFee;
        uint256 validFor;
    }

    /**
     * Struct to store generic information of a badge type.
     * @param emitter The address who created the badge type.
     * @param badgeType The type of the badge (Kleros, custom, etc).
     * @param paused If paused, it is not possible to mint badges for this badge type.
     * @param mintCost The cost for minting a badge, it goes to the emitter.
     * @param mintFee The fee charged for The Badge to the mintCost.
     * @param validFor The time in seconds of how long the badge is valid. (cero for infinite)
     */
    struct BadgeType {
        address emitter;
        string controllerName;
        bool paused;
        uint256 mintCreatorFee;
        uint256 validFor;
        uint256 mintProtocolFee; // in bps. It is applied to mintCreatorFee
    }

    /**
     * =========================
     * Store
     * =========================
     */

    /**
     * @notice emitters are all entities who can create badges
     * registrationOpen variable determines if the register is open or not.
     * emitterAddress => EmitterInfo
     */
    mapping(address => Emitter) public emitters;
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
    event EmitterRegistered(address indexed emitter, string metadata);
    event EmitterUpdated(address indexed emitter, string metadata);
    event BadgeTypeCreated(uint256 indexed badgeTypeID, string metadata);

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__constructor_paramAddressesCanNotBeZero();
    error TheBadge__updateAddresses_paramAddressesCanNotBeZero();
    error TheBadge__onlyEmitter_senderIsNotAnEmitter();
    error TheBadge__onlyAdmin_senderIsNotAdmin();
    error TheBadge__onlyController_senderIsNotTheController();
    error TheBadge__registerEmitter_invalidAddress();
    error TheBadge__registerEmitter_wrongValue();
    error TheBadge__registerEmitter_alreadyRegistered();
    error TheBadge__setBadgeTypeController_emptyName();
    error TheBadge__setBadgeTypeController_notFound();
    error TheBadge__setBadgeTypeController_alreadySet();
    error TheBadge__setControllerStatus_notFound();
    error TheBadge__createBadgeType_invalidMintCost();
    error TheBadge__createBadgeType_invalidController();
    error TheBadge__createBadgeType_controllerIsPaused();
    error TheBadge__createBadgeType_notAnEmitter();
    error TheBadge__createBadgeType_wrongValue();
    error TheBadge__updateBadgeType_notBadgeTypeOwner();
    error TheBadge__updateBadgeType_invalidMintCost();
    error TheBadge__updateBadgeType_badgeTypeNotFound();
    error TheBadge__updateBadgeTypeFee_badgeTypeNotFound();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_badgeTypeNotFound();
    error TheBadge__requestBadge_controllerIsPaused();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__updateEmitter_notFound();
    error TheBadge__ERC1155_notAllowed();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyEmitter() {
        Emitter storage emitter = emitters[msg.sender];
        if (bytes(emitter.metadata).length == 0) {
            revert TheBadge__onlyEmitter_senderIsNotAnEmitter();
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
        uint256 _minBadgeMintValue,
        uint256 _createBadgeTypeValue,
        uint256 _registerEmitterValue
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadgeDefaultFee = _mintBadgeDefaultFee;
        minBadgeMintValue = _minBadgeMintValue;
        createBadgeTypeValue = _createBadgeTypeValue;
        registerEmitterValue = _registerEmitterValue;
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
     * @notice Register a new emitter
     * @param _metadata IPFS url
     */
    function registerEmitter(string memory _metadata) public payable {
        if (msg.value != registerEmitterValue) {
            revert TheBadge__registerEmitter_wrongValue();
        }

        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        Emitter storage emitter = emitters[_msgSender()];
        if (bytes(emitter.metadata).length != 0) {
            revert TheBadge__registerEmitter_alreadyRegistered();
        }

        emitter.metadata = _metadata;

        emit EmitterRegistered(_msgSender(), emitter.metadata);
    }

    /**
     * @dev Allow to update some emitter's attributes for the admin
     * @param _emitter The emitter address
     */
    function updateEmitter(address _emitter, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Emitter storage emitter = emitters[_emitter];

        if (bytes(emitter.metadata).length == 0) {
            revert TheBadge__updateEmitter_notFound();
        }

        if (bytes(_metadata).length > 0) {
            emitter.metadata = _metadata;
        }

        emit EmitterUpdated(_emitter, _metadata);
    }

    // TODO: rename emitter with creator
    // TODO: suspend/remove emitter

    /**
     * @notice Creates a badge type that will allow users to mint badges of this type.
     */
    function createBadgeType(CreateBadgeType memory args, bytes memory data) public payable onlyEmitter {
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

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__updateBadgeType_badgeTypeNotFound();
        }

        if (_msgSender() != _badgeType.emitter) {
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

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__updateBadgeTypeFee_badgeTypeNotFound();
        }

        _badgeType.mintProtocolFee = feeInBps;
    }

    /**
     * @notice returns the cost for minting a bade of a badgeType
     */
    function badgeRequestValue(uint256 badgeTypeId) public view returns (uint256) {
        BadgeType storage _badgeType = badgeType[badgeTypeId];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        return controller.badgeRequestValue(badgeTypeId) + _badgeType.mintCreatorFee;
    }

    /**
     * @notice allows the feeCollector collect contract balance
     */
    function collectFees() public {
        payable(feeCollector).transfer(address(this).balance);
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
