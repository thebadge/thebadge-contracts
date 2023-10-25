// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { ERC1155Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import { ERC1155URIStorageUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155URIStorageUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { ITheBadge } from "../../interfaces/ITheBadge.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { TheBadgeStore } from "./TheBadgeStore.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

/// @custom:security-contact hello@thebadge.com
contract TheBadge is
    Initializable,
    ERC1155Upgradeable,
    ERC1155URIStorageUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable,
    TheBadgeRoles,
    ITheBadge,
    ReentrancyGuardUpgradeable
{
    TheBadgeStore public _badgeStore;
    string public name;
    string public symbol;

    /**
     * =========================
     * Events
     * =========================
     */
    event Initialize(address indexed admin);
    event PaymentMade(
        address indexed recipient,
        address payer,
        uint256 amount,
        LibTheBadge.PaymentType indexed paymentType,
        uint256 indexed badgeModelId,
        string controllerName
    );
    event BadgeRequested(
        uint256 indexed badgeModelID,
        uint256 indexed badgeID,
        address indexed recipient,
        address controller,
        uint256 controllerBadgeId
    );
    event BadgeTransferred(uint256 indexed badgeId, address indexed origin, address indexed destination);
    event ProtocolSettingsUpdated();

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyBadgeModelMintable(uint256 badgeModelId) {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadge.TheBadge__requestBadge_badgeModelNotFound();
        }

        if (_badgeModel.paused) {
            revert LibTheBadge.TheBadge__requestBadge_isPaused();
        }

        if (_badgeModel.suspended) {
            revert LibTheBadge.TheBadge__requestBadge_isSuspended();
        }

        if (_badgeModelController.paused) {
            revert LibTheBadge.TheBadge__requestBadge_controllerIsPaused();
        }

        TheBadgeStore.User memory user = _badgeStore.getUser(_badgeModel.creator);
        if (user.suspended == true) {
            revert LibTheBadge.TheBadge__requestBadge_badgeModelIsSuspended();
        }

        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address badgeStore) public initializer {
        __ERC1155_init("");
        __AccessControl_init();
        __Pausable_init();
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        _badgeStore = TheBadgeStore(payable(badgeStore));
        name = "TheBadge";
        symbol = "BGD";
        emit Initialize(admin);
    }

    /*
     * @notice Receives a badgeModel, and user account, the token data ipfsURI and the controller's data and mints the badge for the user
     * @param badgeModelId id of theBadgeModel
     * @param account the recipient address of the badge, if empty and it's allowed, its stored on the controller's address until its claimed
     * @param tokenURI url of the data of the token stored in IPFS
     * @param data metaEvidence for the controller
     */
    function mint(
        uint256 badgeModelId,
        address account,
        string memory tokenURI,
        bytes memory data
    ) external payable onlyBadgeModelMintable(badgeModelId) nonReentrant {
        // Re-declaring variables reduces the stack tree and avoid compilation errors
        uint256 _badgeModelId = badgeModelId;
        address _account = account;
        address _mintingAccount = _account;
        bytes memory _data = data;
        string memory _tokenURI = tokenURI;

        if (msg.value < mintValue(_badgeModelId)) {
            revert LibTheBadge.TheBadge__requestBadge_wrongValue();
        }

        // Distribute fees
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(_badgeModelId);
        if (_badgeModel.mintCreatorFee > 0) {
            payProtocolFees(_badgeModelId);
        }

        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        // If no recipient has been defined, we ask the controller if it's allowed to temporally store
        // the asset within his address until the user claims the ownership
        if (_account == address(0)) {
            if (!controller.isMintableToController(_badgeModelId, _account)) {
                revert LibTheBadge.TheBadge__requestBadge_badgeNotMintable();
            }
            _mintingAccount = _badgeModelController.controller;
        }

        // save asset info
        uint256 badgeId = _badgeStore.getCurrentBadgeIdCounter();

        // Mints the badge on the controller
        uint256 controllerBadgeId = controller.mint{ value: (msg.value - _badgeModel.mintCreatorFee) }(
            _msgSender(),
            _badgeModelId,
            badgeId,
            _data,
            _mintingAccount
        );

        // Mints the badge on the ERC1155 collection
        _setURI(badgeId, _tokenURI);
        // Account: badge recipient; badgeId: the id of the badge; value: amount of badges to create (always 1), data: data of the badge (always null)
        // For details check: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC1155/ERC1155Upgradeable.sol#L303C72-L303C76
        _mint(_mintingAccount, badgeId, 1, "0x");

        // Stores the badge
        uint256 dueDate = _badgeModel.validFor == 0 ? 0 : block.timestamp + _badgeModel.validFor;
        TheBadgeStore.Badge memory badge = TheBadgeStore.Badge(_badgeModelId, _mintingAccount, dueDate, true);
        _badgeStore.addBadge(badgeId, badge);
        emit BadgeRequested(
            _badgeModelId,
            badgeId,
            _mintingAccount,
            _badgeModelController.controller,
            controllerBadgeId
        );
    }

    /**
     * @notice Given a badgeId and data related to the recipient, claims the given badge to the recipient address
     * @param badgeId the id of the badge
     * @param data containing information related to the recipient address
     */
    function claim(uint256 badgeId, bytes calldata data) public {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        TheBadgeStore.Badge memory badge = _badgeStore.getBadge(badgeId);
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        if (badge.initialized == false) {
            revert LibTheBadge.TheBadge__requestBadge_badgeNotClaimable();
        }

        if (controller.isClaimable(badgeId) == false) {
            revert LibTheBadge.TheBadge__requestBadge_badgeNotClaimable();
        }

        address claimAddress = controller.claim(badgeId, data, _msgSender());
        _badgeStore.transferBadge(badgeId, address(_badgeModelController.controller), claimAddress);
        emit BadgeTransferred(badgeId, address(_badgeModelController.controller), claimAddress);
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a challenge against the controller
     * @param badgeId the id of the badge
     * @param data encoded ipfs hash containing the evidence to generate the challenge
     */
    function challenge(uint256 badgeId, bytes calldata data) external payable {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        controller.challenge{ value: (msg.value) }(badgeId, data, _msgSender());
    }

    /**
     * @notice Given a badge and the evidenceHash, submits a removal request against the controller
     * @param badgeId the id of the badge
     * @param data encoded ipfs hash containing the evidence to generate the removal request
     */
    function removeItem(uint256 badgeId, bytes calldata data) external payable {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        controller.removeItem{ value: (msg.value) }(badgeId, data, _msgSender());
    }

    /**
     * @notice Given a badge and the evidenceHash, adds more evidence to a case
     * @param badgeId the id of the badge
     * @param data encoded ipfs hash adding more evidence to a submission
     */
    function submitEvidence(uint256 badgeId, bytes calldata data) external {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        controller.submitEvidence(badgeId, data, _msgSender());
    }

    /*
     * @notice Updates the value of the protocol: _mintBadgeDefaultFee
     * @param _mintBadgeDefaultFee the default fee that TheBadge protocol charges for each mint (in bps)
     */
    function updateMintBadgeDefaultProtocolFee(uint256 _mintBadgeDefaultFee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _badgeStore.updateMintBadgeDefaultProtocolFee(_mintBadgeDefaultFee);
        emit ProtocolSettingsUpdated();
    }

    /*
     * @notice Updates the value of the protocol: _createBadgeModelValue
     * @param _createBadgeModelValue the default fee that TheBadge protocol charges for each badge model creation (in bps)
     */
    function updateCreateBadgeModelProtocolFee(uint256 _createBadgeModelValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _badgeStore.updateCreateBadgeModelProtocolFee(_createBadgeModelValue);
        emit ProtocolSettingsUpdated();
    }

    /*
     * @notice Updates the value of the protocol: _registerCreatorValue
     * @param _registerCreatorValue the default fee that TheBadge protocol charges for each user registration (in bps)
     */
    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _badgeStore.updateRegisterCreatorProtocolFee(_registerCreatorValue);
        emit ProtocolSettingsUpdated();
    }

    function payProtocolFees(uint256 _badgeModelId) internal {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(_badgeModelId);
        address feeCollector = _badgeStore.feeCollector();
        uint256 theBadgeFee = calculateFee(_badgeModel.mintCreatorFee, _badgeModel.mintProtocolFee);
        uint256 creatorPayment = _badgeModel.mintCreatorFee - theBadgeFee;

        (bool protocolFeeSent, ) = payable(feeCollector).call{ value: theBadgeFee }("");
        if (protocolFeeSent == false) {
            revert LibTheBadge.TheBadge__mint_protocolFeesPaymentFailed();
        }
        emit PaymentMade(
            feeCollector,
            _msgSender(),
            theBadgeFee,
            LibTheBadge.PaymentType.ProtocolFee,
            _badgeModelId,
            "0x"
        );

        (bool creatorFeeSent, ) = payable(_badgeModel.creator).call{ value: creatorPayment }("");
        if (creatorFeeSent == false) {
            revert LibTheBadge.TheBadge__mint_creatorFeesPaymentFailed();
        }
        emit PaymentMade(
            _badgeModel.creator,
            feeCollector,
            creatorPayment,
            LibTheBadge.PaymentType.CreatorMintFee,
            _badgeModelId,
            "0x"
        );
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
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
        TheBadgeStore.Badge memory _badge = _badgeStore.getBadge(badgeId);

        if (_badge.initialized == false || _badge.account != account) {
            return 0;
        }

        if (isExpired(badgeId) == true) {
            return 0;
        }

        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(_badge.badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        return controller.isAssetActive(badgeId) ? 1 : 0;
    }

    /*
     * @notice given an account address and a badgeModelId returns how many badges of each model owns the user
     * @param account user address
     * @param badgeModelId ID of the badgeModel
     */
    function balanceOfBadgeModel(address account, uint256 badgeModelId) public view returns (uint256) {
        uint256[] memory userMintedBadgesByBadgeModel = _badgeStore.getUserMintedBadgesByBadgeModel(
            badgeModelId,
            account
        );
        if (userMintedBadgesByBadgeModel.length == 0) {
            return 0;
        }

        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        uint256 balance = 0;
        for (uint256 i = 0; i < userMintedBadgesByBadgeModel.length; i++) {
            uint256 badgeId = userMintedBadgesByBadgeModel[i];
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
        TheBadgeStore.Badge memory _badge = _badgeStore.getBadge(badgeId);

        if (_badge.initialized == false) {
            return false;
        }

        // Badge configured to be life-time
        if (_badge.dueDate == 0) {
            return false;
        }

        return _badge.dueDate <= block.timestamp ? true : false;
    }

    /**
     * @notice Given a badgeId, returns the cost to challenge the item
     * @param badgeId the id of the badge
     */
    function getChallengeDepositValue(uint256 badgeId) public view override(ITheBadge) returns (uint256) {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        return controller.getChallengeDepositValue(badgeId);
    }

    /**
     * @notice Given a badgeId, returns the cost to challenge to remove the item
     * @param badgeId the id of the badge
     */
    function getRemovalDepositValue(uint256 badgeId) public view override(ITheBadge) returns (uint256) {
        uint256 badgeModelId = getBadgeModelIdFromBadgeId(badgeId);
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );
        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);

        return controller.getRemovalDepositValue(badgeId);
    }

    /*
     * @notice Receives the mintCreatorFee and the mintProtocolFee in bps and returns how much is the protocol fee
     * @param mintCreatorFee fee that the creator charges for each mint
     * @param mintProtocolFeeInBps fee that TheBadge protocol charges from the creator revenue
     */
    function calculateFee(uint256 mintCreatorFee, uint256 mintProtocolFeeInBps) internal pure returns (uint256) {
        if ((mintCreatorFee * mintProtocolFeeInBps) < 10_000) {
            revert LibTheBadge.TheBadge__calculateFee_protocolFeesInvalidValues();
        }
        return (mintCreatorFee * mintProtocolFeeInBps) / 10_000;
    }

    /**
     * @notice Given a badgeId, returns the id of its model if exists
     * @param badgeId the id of the badge
     */
    function getBadgeModelIdFromBadgeId(uint256 badgeId) internal view returns (uint256) {
        TheBadgeStore.Badge memory _badge = _badgeStore.getBadge(badgeId);

        if (_badge.initialized == false) {
            revert LibTheBadge.TheBadge__requestBadge_badgeNotFound();
        }
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(_badge.badgeModelId);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadge.TheBadge__requestBadge_badgeModelNotFound();
        }
        return _badge.badgeModelId;
    }

    /*
     * @notice given badgeModelId returns the cost of minting that badge (controller minting fee + mintCreatorFee)
     * @param badgeModelId the id of the badgeModel
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        TheBadgeStore.BadgeModel memory _badgeModel = _badgeStore.getBadgeModel(badgeModelId);

        if (_badgeModel.creator == address(0)) {
            revert LibTheBadge.TheBadge__requestBadge_badgeModelNotFound();
        }

        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            _badgeModel.controllerName
        );

        IBadgeModelController controller = IBadgeModelController(_badgeModelController.controller);
        return controller.mintValue(badgeModelId) + _badgeModel.mintCreatorFee;
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
        revert LibTheBadge.TheBadge__SBT();
    }

    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal override whenNotPaused {
        // Check if the from address is one of the badgeModelControllers
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelControllerByAddress(
            from
        );

        if (from != address(0) && _badgeModelController.initialized == false) {
            revert LibTheBadge.TheBadge__SBT();
        }

        super._update(from, to, ids, amounts);
    }

    // solhint-disable-next-line
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155Upgradeable, AccessControlUpgradeable, ITheBadge) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
