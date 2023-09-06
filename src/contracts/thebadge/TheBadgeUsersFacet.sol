// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
/**
 * =========================
 * Contains all the logic related to badge models (but not badges)
 * =========================
 */

import { IBadgeModelController } from "../../interfaces/IBadgeModelController.sol";
import { ITheBadgeUsers } from "../../interfaces/ITheBadgeUsers.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadgeUsers } from "../libraries/LibTheBadgeUsers.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";
import { TheBadgeStore } from "./TheBadgeStore.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TheBadgeUsersFacet is ITheBadgeUsers, TheBadgeRoles, OwnableUpgradeable {
    TheBadgeStore private _badgeStore;
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
            emit LibTheBadge.PaymentMade(
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
    }

    /**
     * @notice Given an user and new metadata, updates the metadata of the user
     * @param _user user address
     * @param _metadata IPFS url
     */
    function updateUser(address _user, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_user);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (bytes(_metadata).length > 0) {
            user.metadata = _metadata;
        }

        _badgeStore.updateUser(_msgSender(), user);
    }

    function suspendUser(address _user, bool suspended) public onlyRole(PAUSER_ROLE) {
        TheBadgeStore.User memory user = _badgeStore.getUser(_user);

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        user.suspended = suspended;
        _badgeStore.updateUser(_msgSender(), user);
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
            emit LibTheBadge.PaymentMade(
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
        emit LibTheBadgeUsers.UserVerificationRequested(_msgSender(), evidenceUri, controllerName);
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
        emit LibTheBadgeUsers.UserVerificationExecuted(_user, controllerName, verify);
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
}
