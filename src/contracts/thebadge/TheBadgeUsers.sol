// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;
/**
 * =========================
 * Contains all the logic related to TheBadge users
 * =========================
 */

import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { ITheBadgeUsers } from "../../interfaces/ITheBadgeUsers.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadgeUsers } from "../libraries/LibTheBadgeUsers.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";
import { TheBadgeStore } from "./TheBadgeStore.sol";
import { TheBadgeUsersStore } from "./TheBadgeUsersStore.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract TheBadgeUsers is ITheBadgeUsers, TheBadgeRoles, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    TheBadgeStore public _badgeStore;
    TheBadgeUsersStore public _badgeUsersStore;

    /**
     * =========================
     * Events
     * =========================
     */
    event Initialize(address indexed admin);
    event UserRegistered(address indexed user, string metadata);
    event UserVerificationRequested(address indexed user, string metadata, string controllerName);
    event UserVerificationExecuted(address indexed user, string controllerName, bool verify);
    event UpdatedUser(address indexed userAddress, string metadata, bool suspended, bool isCreator, bool deleted);
    event PaymentMade(
        address indexed recipient,
        address payer,
        uint256 amount,
        LibTheBadge.PaymentType indexed paymentType,
        uint256 indexed badgeModelId,
        string controllerName
    );
    event ProtocolSettingsUpdated();

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyRegisteredUser(address _user) {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_user);
        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__onlyUser_userNotFound();
        }
        if (user.suspended == true) {
            revert LibTheBadgeUsers.TheBadge__users__onlyCreator_creatorIsSuspended();
        }
        _;
    }

    modifier existingBadgeModelController(string memory controllerName) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        if (_badgeModelController.controller == address(0)) {
            revert LibTheBadge.TheBadge__controller_invalidController();
        }
        if (_badgeModelController.initialized == false) {
            revert LibTheBadge.TheBadge__controller_invalidController();
        }
        if (_badgeModelController.paused) {
            revert LibTheBadge.TheBadge__controller_controllerIsPaused();
        }
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(address admin, address badgeStore, address badgeUsersStore) public initializer {
        __Ownable_init(admin);
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(USER_MANAGER_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
        _grantRole(UPGRADER_ROLE, admin);
        _grantRole(VERIFIER_ROLE, admin);
        _badgeStore = TheBadgeStore(payable(badgeStore));
        _badgeUsersStore = TheBadgeUsersStore(payable(badgeUsersStore));
        emit Initialize(admin);
    }

    /**
     * =========================
     * Getters
     * =========================
     */
    function getUser(address userAddress) external view returns (TheBadgeUsersStore.User memory) {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(userAddress);

        return user;
    }

    function getUserVerifyStatus(
        address controllerAddress,
        address userAddress
    ) external view returns (TheBadgeUsersStore.UserVerification memory) {
        return _badgeUsersStore.getUserVerifyStatus(controllerAddress, userAddress);
    }

    function getRegisterFee() external view returns (uint256) {
        return _badgeUsersStore.registerUserProtocolFee();
    }

    function getVerificationFee(
        string memory controllerName
    ) public view existingBadgeModelController(controllerName) returns (uint256) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        return IBadgeModelController(_badgeModelController.controller).getVerifyUserProtocolFee();
    }

    function isUserVerified(
        address _user,
        string memory controllerName
    ) public view existingBadgeModelController(controllerName) returns (bool) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        TheBadgeUsersStore.UserVerification memory verifyStatus = _badgeUsersStore.getUserVerifyStatus(
            _badgeModelController.controller,
            _user
        );
        if (
            verifyStatus.initialized == true &&
            verifyStatus.verificationStatus == LibTheBadgeUsers.VerificationStatus.Verified
        ) {
            return true;
        }
        return false;
    }

    /**
     * =========================
     * Setters
     * =========================
     */

    /**
     * @notice Register a new user
     * @param _metadata IPFS url with the metadata of the user
     */
    function registerUser(string memory _metadata, bool _isCompany) public payable {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_msgSender());
        if (bytes(user.metadata).length != 0) {
            revert LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered();
        }

        uint256 registerUserProtocolFee = _badgeUsersStore.registerUserProtocolFee();
        if (msg.value != registerUserProtocolFee) {
            revert LibTheBadgeUsers.TheBadge__registerUser_wrongValue();
        }
        if (msg.value > 0) {
            address feeCollector = _badgeStore.feeCollector();
            payable(feeCollector).transfer(msg.value);
            emit PaymentMade(
                feeCollector,
                _msgSender(),
                msg.value,
                LibTheBadge.PaymentType.UserRegistrationFee,
                0,
                "0x"
            );
        }

        user.metadata = _metadata;
        user.isCompany = _isCompany;
        user.isCreator = false;
        user.suspended = false;
        user.initialized = true;

        _badgeUsersStore.createUser(_msgSender(), user);
        emit UserRegistered(_msgSender(), user.metadata);
    }

    /**
     * @notice Allows users to update their profile metadata
     * @param _metadata IPFS url
     */
    function updateProfile(string memory _metadata) public {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_msgSender());

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (bytes(_metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_wrongMetadata();
        }

        user.metadata = _metadata;
        _badgeUsersStore.updateUser(_msgSender(), user);
        emit UpdatedUser(_msgSender(), user.metadata, user.suspended, user.isCreator, false);
    }

    /**
     * @notice Given an user and new metadata, updates the metadata of the user
     * @param _userAddress user address
     * @param _metadata IPFS url
     */
    function updateUser(address _userAddress, string memory _metadata) public onlyRole(USER_MANAGER_ROLE) {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (bytes(_metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_wrongMetadata();
        }

        user.metadata = _metadata;
        _badgeUsersStore.updateUser(_userAddress, user);
        emit UpdatedUser(_userAddress, user.metadata, user.suspended, user.isCreator, false);
    }

    /**
     * @notice Suspends or remove the suspension to the user, avoiding him to create badge models
     * @param _userAddress user address
     * @param suspended boolean
     */
    function suspendUser(address _userAddress, bool suspended) public onlyRole(PAUSER_ROLE) {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        user.suspended = suspended;
        _badgeUsersStore.updateUser(_userAddress, user);
        emit UpdatedUser(_userAddress, user.metadata, suspended, user.isCreator, false);
    }

    /**
     * @notice Given an user, sets him as creator
     * @param _userAddress user address
     */
    function makeUserCreator(address _userAddress) public onlyRole(USER_MANAGER_ROLE) {
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (user.isCreator == true) {
            revert LibTheBadgeUsers.TheBadge__onlyCreator_senderIsAlreadyACreator();
        }

        user.isCreator = true;
        _badgeUsersStore.updateUser(_userAddress, user);
        emit UpdatedUser(_userAddress, user.metadata, user.suspended, user.isCreator, false);
    }

    /**
     * @notice Creates a request to Verify an user on behalf of the user
     * @param controllerName the controller to verify the user
     * @param evidenceUri IPFS uri with the evidence required for the verification
     */
    function submitUserVerification(
        address userToVerify,
        string memory controllerName,
        string memory evidenceUri
    )
        public
        payable
        onlyRole(VERIFIER_ROLE)
        onlyRegisteredUser(userToVerify)
        existingBadgeModelController(controllerName)
        nonReentrant
    {
        submitUserVerificationLogic(userToVerify, controllerName, evidenceUri);
    }

    /**
     * @notice Creates a request to Verify an user in an specific badgeModelController
     * @param evidenceUri IPFS uri with the evidence required for the verification
     */
    function submitUserVerification(
        string memory controllerName,
        string memory evidenceUri
    ) public payable onlyRegisteredUser(_msgSender()) existingBadgeModelController(controllerName) nonReentrant {
        submitUserVerificationLogic(_msgSender(), controllerName, evidenceUri);
    }

    /**
     * @notice Creates a request to Verify an user in an specific badgeModelController
     * @param _user user address to verify
     * @param controllerName id of the controller to execute the verification
     * @param verify true if the user should be verified, false otherwise
     */
    function executeUserVerification(
        address _user,
        string memory controllerName,
        bool verify
    ) public onlyRole(VERIFIER_ROLE) existingBadgeModelController(controllerName) onlyRegisteredUser(_user) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );

        TheBadgeUsersStore.UserVerification memory _userVerification = _badgeUsersStore.getUserVerifyStatus(
            _badgeModelController.controller,
            _user
        );

        if (_userVerification.initialized == false) {
            revert LibTheBadgeUsers.TheBadge__verifyUser__userVerificationNotStarted();
        }

        LibTheBadgeUsers.VerificationStatus _verificationStatus = verify
            ? LibTheBadgeUsers.VerificationStatus.Verified
            : LibTheBadgeUsers.VerificationStatus.VerificationRejected;

        _badgeUsersStore.updateUserVerificationStatus(_badgeModelController.controller, _user, _verificationStatus);
        emit UserVerificationExecuted(_user, controllerName, verify);
    }

    /*
     * @notice Updates the value of the protocol: _registerCreatorValue
     * @param _registerCreatorValue the default fee that TheBadge protocol charges for each user registration (in bps)
     */
    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _badgeUsersStore.updateRegisterCreatorProtocolFee(_registerCreatorValue);
        emit ProtocolSettingsUpdated();
    }

    function submitUserVerificationLogic(
        address userToVerify,
        string memory controllerName,
        string memory evidenceUri
    ) internal {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        TheBadgeUsersStore.User memory user = _badgeUsersStore.getUser(userToVerify);
        string memory _controllerName = controllerName;
        address feeCollector = _badgeStore.feeCollector();

        // The verification fee differs in each controller
        uint256 verifyCreatorProtocolFee = IBadgeModelController(_badgeModelController.controller)
            .getVerifyUserProtocolFee();

        if (msg.value != verifyCreatorProtocolFee) {
            revert LibTheBadgeUsers.TheBadge__verifyUser_wrongValue();
        }

        if (msg.value > 0) {
            // Transfers the verification fee to the collector
            (bool verifyCreatorProtocolFeeSent, ) = payable(feeCollector).call{ value: msg.value }("");
            if (verifyCreatorProtocolFeeSent == false) {
                revert LibTheBadgeUsers.TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();
            }
            emit PaymentMade(
                feeCollector,
                userToVerify,
                msg.value,
                LibTheBadge.PaymentType.UserVerificationFee,
                0,
                _controllerName
            );
        }

        TheBadgeUsersStore.UserVerification memory _userVerification = _badgeUsersStore.getUserVerifyStatus(
            _badgeModelController.controller,
            userToVerify
        );

        if (_userVerification.initialized == true) {
            revert LibTheBadgeUsers.TheBadge__verifyUser__userVerificationAlreadyStarted();
        }

        _userVerification.user = userToVerify;
        _userVerification.userMetadata = user.metadata;
        _userVerification.verificationEvidence = evidenceUri;
        _userVerification.verificationStatus = LibTheBadgeUsers.VerificationStatus.VerificationSubmitted;
        _userVerification.verificationController = _badgeModelController.controller;
        _userVerification.initialized = true;

        _badgeUsersStore.createUserVerificationStatus(
            _badgeModelController.controller,
            userToVerify,
            _userVerification
        );
        emit UserVerificationRequested(userToVerify, evidenceUri, controllerName);
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
