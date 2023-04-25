// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin-upgrade/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin-upgrade/contracts/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin-upgrade/contracts/security/PausableUpgradeable.sol";
import "@openzeppelin-upgrade/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgrade/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin-upgrade/contracts/utils/CountersUpgradeable.sol";

import "./TheBadgeRoles.sol";
import "./TheBadgeLogic.sol";

/// @custom:security-contact hello@thebadge.com
contract TheBadge is
    Initializable,
    ERC1155Upgradeable,
    ERC1155URIStorageUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    TheBadgeRoles,
    TheBadgeLogic
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter internal badgeIds;

    struct Badge {
        uint256 badgeTypeId;
        uint256 dueDate;
    }

    /**
     * =========================
     * Store
     * =========================
     */

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

    event BadgeRequested(uint256 indexed badgeTypeID, uint256 indexed badgeID, address indexed wallet);

    /**
     * =========================
     * Errors
     * =========================
     */

    error TheBadge__SBT();

    /**
     * =========================
     * Methods
     * =========================
     */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address feeCollectorAddress, address minterAddress) public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minterAddress);
        _grantRole(UPGRADER_ROLE, msg.sender);

        registerEmitterValue = uint256(0);
        mintBadgeDefaultFee = uint256(4000); // in bps
        minBadgeMintValue = uint256(0);
        createBadgeTypeValue = uint256(0);
        feeCollector = feeCollectorAddress;
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // function mint(address account, uint256 id, uint256 amount, bytes memory data) public onlyRole(MINTER_ROLE) {
    //     _mint(account, id, amount, data);
    // }

    /**
     * @notice request the emission of a badge of a badgeType
     */
    function mint(uint256 badgeTypeId, address account, string memory tokenURI, bytes memory data) external payable {
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        // TODO: add onlyRole(MINTER_ROLE)
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        BadgeType storage _badgeType = badgeType[badgeTypeId];
        BadgeTypeController storage _badgeTypeController = badgeTypeController[_badgeType.controllerName];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        if (_badgeType.emitter == address(0)) {
            revert TheBadge__requestBadge_badgeTypeNotFound();
        }

        if (msg.value < badgeRequestValue(badgeTypeId)) {
            revert TheBadge__requestBadge_wrongValue();
        }

        if (_badgeType.paused) {
            revert TheBadge__requestBadge_isPaused();
        }

        if (_badgeTypeController.paused) {
            revert TheBadge__requestBadge_controllerIsPaused();
        }

        // distribute fees
        if (_badgeType.mintCreatorFee > 0) {
            uint256 theBadgeFee = calculateFee(_badgeType.mintCreatorFee, _badgeType.mintProtocolFee);
            payable(feeCollector).transfer(theBadgeFee);
            payable(_badgeType.emitter).transfer(_badgeType.mintCreatorFee - theBadgeFee);
        }

        uint256 badgeId = badgeIds.current();
        _setURI(badgeId, tokenURI);
        _mint(account, badgeId, 1, "0x");

        uint256 validFor = _badgeType.validFor == 0 ? 0 : block.timestamp + _badgeType.validFor;
        badge[badgeId][account] = Badge(badgeTypeId, validFor);

        controller.requestBadge{ value: (msg.value - _badgeType.mintCreatorFee) }(
            _msgSender(),
            badgeTypeId,
            account,
            data
        );

        badgeIds.increment();
    }

    /**
     * =========================
     * Overrides
     * =========================
     */

    function uri(
        uint256
    ) public view virtual override(ERC1155URIStorageUpgradeable, ERC1155Upgradeable) returns (string memory) {
        // TODO: return token uri per badge
        return "";
    }

    function _setApprovalForAll(address, address, bool) internal pure override {
        revert TheBadge__SBT();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override whenNotPaused {
        if (!hasRole(MINTER_ROLE, _msgSender())) {
            revert TheBadge__SBT();
        }

        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
