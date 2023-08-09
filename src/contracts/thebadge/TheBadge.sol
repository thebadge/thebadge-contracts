// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./TheBadgeRoles.sol";
import "./TheBadgeStore.sol";
import "./TheBadgeModels.sol";
import "../../interfaces/ITheBadge.sol";

/// @custom:security-contact hello@thebadge.com
contract TheBadge is
    Initializable,
    ERC1155Upgradeable,
    ERC1155URIStorageUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    TheBadgeRoles,
    TheBadgeModels,
    ITheBadge
{
    // Allows to use current() and increment() for badgeModelIds or badgeIds
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address _feeCollector, address minter) public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, minter);
        _grantRole(UPGRADER_ROLE, msg.sender);

        feeCollector = _feeCollector;
        registerCreatorProtocolFee = uint256(0);
        createBadgeModelProtocolFee = uint256(0);
        mintBadgeProtocolDefaultFeeInBps = uint256(1000); // in bps (= 10%)
        emit Initialize(admin, minter);
    }

    /*
     * @notice Receives a badgeModel, and user account, the token data ipfsURI and the controller's data and mints the badge for the user
     * @param badgeModelId id of theBadgeModel
     * @param account user address
     * @param tokenURI url of the data of the token stored in IPFS
     * @param data metaEvidence for the controller
     */
    function mint(uint256 badgeModelId, address account, string memory tokenURI, bytes memory data) external payable {
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        // TODO: add onlyRole(MINTER_ROLE) before going prod
        // +++++++++++++++++++++
        // +++++++++++++++++++++
        BadgeModel storage _badgeModel = badgeModel[badgeModelId];
        BadgeModelController storage _badgeModelController = badgeModelController[_badgeModel.controllerName];
        address controllerAddress = badgeModelController[_badgeModel.controllerName].controller;
        IBadgeModelController controller = IBadgeModelController(controllerAddress);

        if (_badgeModel.creator == address(0)) {
            revert TheBadge__requestBadge_badgeModelNotFound();
        }

        if (msg.value < mintValue(badgeModelId)) {
            revert TheBadge__requestBadge_wrongValue();
        }

        if (_badgeModel.paused) {
            revert TheBadge__requestBadge_isPaused();
        }

        if (_badgeModelController.paused) {
            revert TheBadge__requestBadge_controllerIsPaused();
        }

        // distribute fees
        if (_badgeModel.mintCreatorFee > 0) {
            uint256 theBadgeFee = calculateFee(_badgeModel.mintCreatorFee, _badgeModel.mintProtocolFee);
            uint256 creatorPayment = _badgeModel.mintCreatorFee - theBadgeFee;

            (bool protocolFeeSent, ) = payable(feeCollector).call{ value: theBadgeFee }("");
            require(protocolFeeSent, "Failed to pay protocol fees");
            emit PaymentMade(feeCollector, theBadgeFee, PaymentType.ProtocolFee, badgeModelId);

            (bool creatorFeeSent, ) = payable(_badgeModel.creator).call{ value: creatorPayment }("");
            require(creatorFeeSent, "Failed to pay creator fees");
            emit PaymentMade(_badgeModel.creator, theBadgeFee, PaymentType.CreatorFee, badgeModelId);
        }

        // save asset info
        uint256 badgeId = badgeIds.current();
        _setURI(badgeId, tokenURI);
        // Account: badge recipient; badgeId: the id of the badge; value: amount of badges to create (always 1), data: data of the badge (always null)
        // This creates a new badge with id: badgeId
        // For details check: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC1155/ERC1155Upgradeable.sol#L303C72-L303C76
        _mint(account, badgeId, 1, "0x");
        uint256 dueDate = _badgeModel.validFor == 0 ? 0 : block.timestamp + _badgeModel.validFor;
        badge[badgeId] = Badge(badgeModelId, account, dueDate, true);
        badgeModelsByAccount[badgeModelId][account].push(badgeId);

        uint256 controllerBadgeId = controller.mint{ value: (msg.value - _badgeModel.mintCreatorFee) }(
            _msgSender(),
            badgeModelId,
            badgeId,
            data
        );

        badgeIds.increment();
        emit BadgeRequested(badgeModelId, badgeId, account, controllerAddress, controllerBadgeId);
    }

    /*
     * ERC-20
     * @notice Given an user account and a badgeId, returns 1 if the user has the badge or 0 if not
     * @param account address of the user
     * @param badgeId identifier of the badge inside a badgeModel
     */
    function balanceOf(
        address account,
        uint256 badgeId
    ) public view override(ERC1155Upgradeable, ITheBadge) returns (uint256) {
        Badge memory _badge = badge[badgeId];

        if (_badge.initialized == false || _badge.account != account) {
            return 0;
        }

        if (isExpired(badgeId) == true) {
            return 0;
        }

        BadgeModel memory _badgeModel = badgeModel[_badge.badgeModelId];
        IBadgeModelController controller = IBadgeModelController(
            badgeModelController[_badgeModel.controllerName].controller
        );

        return controller.isAssetActive(badgeId) ? 1 : 0;
    }

    /*
     * @notice given an account address and a badgeModelId returns how many badges of each model owns the user
     * @param account user address
     * @param badgeModelId ID of the badgeModel
     */
    function balanceOfBadgeModel(address account, uint256 badgeModelId) public view returns (uint256) {
        if (badgeModelsByAccount[badgeModelId][account].length == 0) {
            return 0;
        }

        BadgeModel memory _badgeModel = badgeModel[badgeModelId];
        IBadgeModelController controller = IBadgeModelController(
            badgeModelController[_badgeModel.controllerName].controller
        );

        uint256 balance = 0;
        for (uint i = 0; i < badgeModelsByAccount[badgeModelId][account].length; i++) {
            uint256 badgeId = badgeModelsByAccount[badgeModelId][account][i];
            if (isExpired(badgeId) == false && controller.isAssetActive(badgeId)) {
                balance++;
            }
        }

        return balance;
    }

    /*
     * @notice Given a badgeId, returns true if the badge has expired (dueDate <= currentTime)
     * if the badge is configured as an all-time badge or if the dueTime didn't arrived yet, returns false
     * @param account address of the user
     * @param badgeId identifier of the badge inside a badgeModel
     */
    function isExpired(uint256 badgeId) public view returns (bool) {
        Badge memory _badge = badge[badgeId];

        if (_badge.initialized == false) {
            return false;
        }

        // Badge configured to be life-time
        if (_badge.dueDate == 0) {
            return false;
        }

        return _badge.dueDate <= block.timestamp ? true : false;
    }

    /*
     * @notice Receives the mintCreatorFee and the mintProtocolFee in bps and returns how much is the protocol fee
     * @param mintCreatorFee fee that the creator charges for each mint
     * @param mintProtocolFeeInBps fee that TheBadge protocol charges from the creator revenue
     */
    function calculateFee(uint256 mintCreatorFee, uint256 mintProtocolFeeInBps) internal pure returns (uint256) {
        require((mintCreatorFee * mintProtocolFeeInBps) >= 10_000);
        return (mintCreatorFee * mintProtocolFeeInBps) / 10_000;
    }

    /*
     * @notice Updates values of the protocol: _mintBadgeDefaultFee; _createBadgeModelValue and _registerCreatorValue
     * @param _mintBadgeDefaultFee the default fee that TheBadge protocol charges for each mint (in bps)
     * @param _createBadgeModelValue the default fee that TheBadge protocol charges for each badge model creation (in bps)
     * @param _registerCreatorValue the default fee that TheBadge protocol charges for each user registration (in bps)
     */
    function updateProtocolValues(
        uint256 _mintBadgeDefaultFee,
        uint256 _createBadgeModelValue,
        uint256 _registerCreatorValue
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        mintBadgeProtocolDefaultFeeInBps = _mintBadgeDefaultFee;
        createBadgeModelProtocolFee = _createBadgeModelValue;
        registerCreatorProtocolFee = _registerCreatorValue;
        emit ProtocolSettingsUpdated();
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    /**
     * =========================
     * Overrides
     * =========================
     */

    /*
     * @notice Given a badgeId returns the uri of the erc115 badge token
     * @param badgeId id of a badge inside a model
     */
    function uri(
        uint256 badgeId
    )
        public
        view
        virtual
        override(ERC1155URIStorageUpgradeable, ERC1155Upgradeable, ITheBadge)
        returns (string memory)
    {
        return super.uri(badgeId);
    }

    /**
     * @notice ERC1155 _setApprovalForAll method, returns a soul-bonded token revert message
     */
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
    ) public view override(ERC1155Upgradeable, AccessControlUpgradeable, ITheBadge) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
