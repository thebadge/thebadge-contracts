// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

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
    error TheBadge__requestBadge_badgeTypeNotFound();
    error TheBadge__requestBadge_wrongValue();
    error TheBadge__requestBadge_isPaused();
    error TheBadge__requestBadge_controllerIsPaused();

    /**
     * =========================
     * Methods
     * =========================
     */

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        // TODO: enable this, it was commented until we find a better solution to test UUPS with foundry
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        // _disableInitializers();
    }

    function initialize(address admin, address feeCollector, address minter) public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, msg.sender);

        feeCollector = feeCollector;

        registerCreatorValue = uint256(0);
        createBadgeTypeValue = uint256(0);
        mintBadgeDefaultFee = uint256(5000); // in bps
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function mint(uint256 badgeTypeId, address account, string memory tokenURI, bytes memory data) external payable {
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        // TODO: add onlyRole(MINTER_ROLE) before going prod
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        BadgeType storage _badgeType = badgeType[badgeTypeId];
        BadgeTypeController storage _badgeTypeController = badgeTypeController[_badgeType.controllerName];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        if (_badgeType.creator == address(0)) {
            revert TheBadge__requestBadge_badgeTypeNotFound();
        }

        if (msg.value < mintValue(badgeTypeId)) {
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
            payable(_badgeType.creator).transfer(_badgeType.mintCreatorFee - theBadgeFee);
        }

        // save asset info
        uint256 badgeId = badgeIds.current();
        _setURI(badgeId, tokenURI);
        _mint(account, badgeId, 1, "0x");
        uint256 validFor = _badgeType.validFor == 0 ? 0 : block.timestamp + _badgeType.validFor;
        badge[badgeId] = Badge(badgeTypeId, account, validFor);
        badgeTypesByAccount[badgeTypeId][account].push(badgeId);

        // delegate to badgeType controller the creation of a new badge.
        controller.mint{ value: (msg.value - _badgeType.mintCreatorFee) }(_msgSender(), badgeTypeId, badgeId, data);

        badgeIds.increment();
    }

    function balanceOf(address account, uint256 badgeId) public view override returns (uint256) {
        Badge memory _badge = badge[badgeId];

        if (_badge.badgeTypeId == 0 || _badge.account != account) {
            return 0;
        }

        BadgeType memory _badgeType = badgeType[_badge.badgeTypeId];
        IBadgeController controller = IBadgeController(badgeTypeController[_badgeType.controllerName].controller);

        return controller.isAssetActive(badgeId) ? 1 : 0;
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
        if (from != address(0)) {
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
