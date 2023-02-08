// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
// import "../lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

import "./utils.sol";
import "./interfaces/IBadgeController.sol";

// TODO: add BADGE address as ERC20
contract TheBadge is ERC1155URIStorage {
    address public admin;
    uint256 public badgeIds;
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
        uint256 mintCost;
        uint256 mintFee; // TODO: remove
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
        uint256 mintCost;
        uint256 mintFee;
        uint256 validFor;
    }

    struct Badge {
        BadgeStatus status;
        uint256 dueDate;
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
     * @notice Information related to a specific asset
     * badgeId => address => Badge
     */
    mapping(uint256 => mapping(address => Badge)) public badge;

    /**
     * =========================
     * Events
     * =========================
     */
    event EmitterRegistered(address indexed emitter, address indexed registrant, string metadata);
    event EmitterUpdated(address indexed emitter, string metadata);
    event BadgeTypeCreated(address creator, uint256 badgeId, string metadata);
    event BadgeRequested(
        uint256 indexed badgeId,
        address indexed account,
        address registrant,
        BadgeStatus status,
        uint256 validFor
    );
    event BadgeStatusUpdated(uint256 indexed badgeId, address indexed badgeOwner, BadgeStatus status);

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
    error TheBadge__updateBadgeStatus_notCreated();
    error TheBadge__updateEmitter_notFound();
    error TheBadge__ERC1155_notAllowed();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyAdmin() {
        if (admin != _msgSender()) {
            revert TheBadge__onlyAdmin_senderIsNotAdmin();
        }
        _;
    }

    modifier onlyEmitter() {
        Emitter storage emitter = emitters[_msgSender()];
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

    constructor(address _admin, address _feeCollector) ERC1155("") {
        if (address(0) == _admin || address(0) == _feeCollector) {
            revert TheBadge__constructor_paramAddressesCanNotBeZero();
        }
        registerEmitterValue = uint256(0);
        mintBadgeDefaultFee = uint256(4000); // in bps
        minBadgeMintValue = uint256(0);
        createBadgeTypeValue = uint256(0);
        admin = _admin;
        feeCollector = _feeCollector;
    }

    function updateAddresses(address _admin, address _feeCollector) public onlyAdmin {
        if (address(0) == _admin || address(0) == _feeCollector) {
            revert TheBadge__updateAddresses_paramAddressesCanNotBeZero();
        }
        admin = _admin;
        feeCollector = _feeCollector;
    }

    function updateValues(
        uint256 _mintBadgeDefaultFee,
        uint256 _minBadgeMintValue,
        uint256 _createBadgeTypeValue,
        uint256 _registerEmitterValue
    ) public onlyAdmin {
        mintBadgeDefaultFee = _mintBadgeDefaultFee;
        minBadgeMintValue = _minBadgeMintValue;
        createBadgeTypeValue = _createBadgeTypeValue;
        registerEmitterValue = _registerEmitterValue;
    }

    /**
     * @notice Sets the controller address of a type of badge
     * Once set, can not be modified to avoid losing internal controller state.
     */
    function setBadgeTypeController(string memory _name, address _controller) public onlyAdmin {
        BadgeTypeController storage _badgeTypeController = badgeTypeController[_name];

        if (bytes(_name).length == 0) {
            revert TheBadge__setBadgeTypeController_emptyName();
        }

        if (_controller == address(0)) {
            revert TheBadge__setBadgeTypeController_notFound();
        }

        if (_badgeTypeController.controller != address(0)) {
            revert TheBadge__setBadgeTypeController_alreadySet();
        }

        badgeTypeController[_name] = BadgeTypeController(_controller, false);
    }

    /**
     * @notice change controller status
     */
    function setControllerStatus(string memory _name, bool isPaused) public onlyAdmin {
        BadgeTypeController storage _badgeTypeController = badgeTypeController[_name];

        if (_badgeTypeController.controller == address(0)) {
            revert TheBadge__setControllerStatus_notFound();
        }

        _badgeTypeController.paused = isPaused;
    }

    /**
     * @notice Calculate percentage using basis points
     */
    function _calculateFee(uint256 amount, uint256 bps) private pure returns (uint256) {
        require((amount * bps) >= 10_000);
        return (amount * bps) / 10_000;
    }

    /**
     * @notice Register a new emitter
     * @param _emitter Emitter address
     * @param _metadata IPFS url
     */
    function registerEmitter(address _emitter, string memory _metadata) public payable {
        if (msg.value != registerEmitterValue) {
            revert TheBadge__registerEmitter_wrongValue();
        }
        payable(feeCollector).transfer(msg.value);

        if (_emitter == address(0)) {
            revert TheBadge__registerEmitter_invalidAddress();
        }

        Emitter storage emitter = emitters[_emitter];
        if (bytes(emitter.metadata).length != 0) {
            revert TheBadge__registerEmitter_alreadyRegistered();
        }

        emitter.metadata = _metadata;

        emit EmitterRegistered(_emitter, _msgSender(), emitter.metadata);
    }

    /**
     * @dev Allow to update some emitter's attributes for the admin
     * @param _emitter The emitter address
     */
    function updateEmitter(address _emitter, string memory _metadata) public onlyAdmin {
        Emitter storage emitter = emitters[_emitter];

        if (bytes(emitter.metadata).length == 0) {
            revert TheBadge__updateEmitter_notFound();
        }

        if (bytes(_metadata).length > 0) {
            emitter.metadata = _metadata;
        }

        emit EmitterUpdated(_emitter, _metadata);
    }

    /**
     * @notice Creates a badge type that will allow users to mint badges.
     */
    function createBadgeType(CreateBadgeType memory args, bytes memory data) public payable onlyEmitter {
        if (msg.value != createBadgeTypeValue) {
            revert TheBadge__createBadgeType_wrongValue();
        }

        if (args.mintCost < minBadgeMintValue) {
            revert TheBadge__createBadgeType_invalidMintCost();
        }

        BadgeTypeController storage _badgeTypeController = badgeTypeController[args.controllerName];
        if (_badgeTypeController.controller == address(0)) {
            revert TheBadge__createBadgeType_invalidController();
        }
        if (_badgeTypeController.paused) {
            revert TheBadge__createBadgeType_controllerIsPaused();
        }

        if (msg.value > 0) {
            payable(feeCollector).transfer(msg.value);
        }

        badgeIds++;
        badgeType[badgeIds] = BadgeType(
            _msgSender(),
            args.controllerName,
            false,
            args.mintCost,
            mintBadgeDefaultFee,
            args.validFor
        );

        _setURI(badgeIds, args.metadata);

        emit BadgeTypeCreated(_msgSender(), badgeIds, args.metadata);

        IBadgeController(_badgeTypeController.controller).createBadgeType{ value: (msg.value - createBadgeTypeValue) }(
            badgeIds,
            data
        );
    }

    function updateBadgeType(uint256 badgeId, uint256 mintCost, uint256 validFor, bool paused) public {
        BadgeType storage _badgeType = badgeType[badgeId];

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__updateBadgeType_badgeTypeNotFound();
        }

        if (_msgSender() != _badgeType.emitter) {
            revert TheBadge__updateBadgeType_notBadgeTypeOwner();
        }

        if (mintCost < minBadgeMintValue) {
            revert TheBadge__updateBadgeType_invalidMintCost();
        }

        _badgeType.mintCost = mintCost;
        _badgeType.validFor = validFor;
        _badgeType.paused = paused;
    }

    function updateBadgeTypeFee(uint256 badgeId, uint256 fee) public onlyAdmin {
        BadgeType storage _badgeType = badgeType[badgeId];

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__updateBadgeTypeFee_badgeTypeNotFound();
        }

        _badgeType.mintFee = fee;
    }

    function badgeRequestValue(uint256 badgeId) external view returns (uint256) {
        BadgeType storage _badgeType = badgeType[badgeId];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        return controller.badgeRequestValue(badgeId) + _badgeType.mintCost;
    }

    function requestBadge(uint256 badgeId, address account, bytes memory data) external payable {
        BadgeType storage _badgeType = badgeType[badgeId];
        BadgeTypeController storage _badgeTypeController = badgeTypeController[_badgeType.controllerName];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__requestBadge_badgeTypeNotFound();
        }

        if (msg.value < _badgeType.mintCost) {
            revert TheBadge__requestBadge_wrongValue();
        }

        if (_badgeType.paused) {
            revert TheBadge__requestBadge_isPaused();
        }

        if (_badgeTypeController.paused) {
            revert TheBadge__requestBadge_controllerIsPaused();
        }

        if (_badgeType.mintCost > 0) {
            uint256 theBadgeFee = _calculateFee(_badgeType.mintCost, _badgeType.mintFee);
            payable(feeCollector).transfer(theBadgeFee);
            payable(_badgeType.emitter).transfer(_badgeType.mintCost - theBadgeFee);
        }

        _mint(account, badgeId, 1, "0x");
        BadgeStatus status = BadgeStatus.InReview;
        uint256 validFor = _badgeType.validFor == 0 ? 0 : block.timestamp + _badgeType.validFor;
        badge[badgeId][account] = Badge(status, validFor);

        controller.requestBadge{ value: (msg.value - _badgeType.mintCost) }(_msgSender(), badgeId, account, data);

        emit BadgeRequested(badgeId, account, _msgSender(), status, validFor);
    }

    function updateBadgeStatus(
        uint256 badgeId,
        address badgeOwner,
        BadgeStatus status
    ) public onlyController(msg.sender, badgeId) {
        Badge storage _badge = badge[badgeId][badgeOwner];

        if (_badge.status == BadgeStatus.NotCreated) {
            revert TheBadge__updateBadgeStatus_notCreated();
        }

        _badge.status = status;

        emit BadgeStatusUpdated(badgeId, badgeOwner, status);
    }

    /**
     * @notice returns positive balance when:
     * a. The badge is Approved
     * b. The badge's due date is after now
     * c. if controller.balanceOf returns 1
     */
    function balanceOf(address account, uint256 badgeId) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");

        Badge storage _badge = badge[badgeId][account];

        if (_badge.status == BadgeStatus.NotCreated) {
            return 0;
        }

        if (_badge.dueDate > 0 && block.timestamp > _badge.dueDate) {
            return 0;
        }

        BadgeType storage _badgeType = badgeType[badgeId];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        return controller.balanceOf(badgeId, account);
    }

    function collectFees() public {
        payable(feeCollector).transfer(address(this).balance);
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address, bool) public virtual override {
        revert TheBadge__ERC1155_notAllowed();
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(address, address, uint256, uint256, bytes memory) public virtual override {
        revert TheBadge__ERC1155_notAllowed();
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override {
        revert TheBadge__ERC1155_notAllowed();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
