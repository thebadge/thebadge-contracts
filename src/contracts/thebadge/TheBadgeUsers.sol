// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
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
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TheBadgeUsers is ITheBadgeUsers, TheBadgeRoles, OwnableUpgradeable {
    TheBadgeStore public _badgeStore;

    /**
     * =========================
     * Events
     * =========================
     */
    event UserRegistered(address indexed user, string metadata);
    event CreatorRegistered(address indexed user);
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

    /**
     * =========================
     * Modifiers
     * =========================
     */
    modifier onlyRegisteredUser(address _user) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_user);
        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__onlyUser_userNotFound();
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

    function initialize(address admin, address badgeStore) public initializer {
        __Ownable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _badgeStore = TheBadgeStore(payable(badgeStore));
    }

    /**
     * @notice Register a new user
     * @param _metadata IPFS url with the metadata of the user
     */
    function registerUser(string memory _metadata, bool _isCompany) public payable {
        TheBadgeStore.User memory user = _badgeStore.getUser(_msgSender());
        if (bytes(user.metadata).length != 0) {
            revert LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered();
        }

        uint256 registerUserProtocolFee = _badgeStore.registerUserProtocolFee();
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

        _badgeStore.createUser(_msgSender(), user);
        emit UserRegistered(_msgSender(), user.metadata);
    }

    /**
     * @notice Given an user and new metadata, updates the metadata of the user
     * @param _userAddress user address
     * @param _metadata IPFS url
     */
    function updateUser(address _userAddress, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (bytes(_metadata).length > 0) {
            user.metadata = _metadata;
        }

        _badgeStore.updateUser(_userAddress, user);
        emit UpdatedUser(_userAddress, user.metadata, user.suspended, user.isCreator, false);
    }

    /**
     * @notice Suspends or remove the suspension to the user, avoiding him to create badge models
     * @param _userAddress user address
     * @param suspended boolean
     */
    function suspendUser(address _userAddress, bool suspended) public onlyRole(PAUSER_ROLE) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        user.suspended = suspended;
        _badgeStore.updateUser(_userAddress, user);
    }

    /**
     * @notice Given an user, sets him as creator
     * @param _userAddress user address
     */
    function makeUserCreator(address _userAddress) public onlyRole(USER_MANAGER_ROLE) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_userAddress);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (user.isCreator == true) {
            revert LibTheBadgeUsers.TheBadge__onlyCreator_senderIsAlreadyACreator();
        }

        user.isCreator = true;
        _badgeStore.updateUser(_userAddress, user);
        emit UpdatedUser(_userAddress, user.metadata, user.suspended, user.isCreator, false);
    }

    /**
     * @notice Creates a request to Verify an user in an specific badgeModelController
     * @param evidenceUri IPFS uri with the evidence required for the verification
     */
    function submitUserVerification(
        string memory controllerName,
        string memory evidenceUri
    ) public payable onlyRegisteredUser(_msgSender()) existingBadgeModelController(controllerName) {
        TheBadgeStore.BadgeModelController memory _badgeModelController = _badgeStore.getBadgeModelController(
            controllerName
        );
        TheBadgeStore.User memory user = _badgeStore.getUser(_msgSender());
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
                _msgSender(),
                msg.value,
                LibTheBadge.PaymentType.UserVerificationFee,
                0,
                _controllerName
            );
        }

        IBadgeModelController(_badgeModelController.controller).submitUserVerification(
            _msgSender(),
            user.metadata,
            evidenceUri
        );
        emit UserVerificationRequested(_msgSender(), evidenceUri, controllerName);
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
        IBadgeModelController(_badgeModelController.controller).executeUserVerification(_user, verify);
        emit UserVerificationExecuted(_user, controllerName, verify);
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
        return IBadgeModelController(_badgeModelController.controller).isUserVerified(_user);
    }

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
