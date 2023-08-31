// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
/**
 * =========================
 * Contains all the logic related to badge models (but not badges)
 * =========================
 */

import { IBadgeModelController } from "../../../interfaces/facets/IBadgeModelController.sol";
import { ITheBadgeUsers } from "../../../interfaces/facets/ITheBadgeUsers.sol";
import { LibDiamond } from "../../libraries/LibDiamond.sol";
import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadgeUsers } from "../../libraries/LibTheBadgeUsers.sol";

contract TheBadgeUsers is ITheBadgeUsers, TheBadgeRoles {
    event UserVerificationRequested(address indexed user, string metadata, string controllerName);
    event UserVerificationExecuted(address indexed user, string controllerName, bool verify);
    event UpdatedUserMetadata(address indexed creator, string metadata);
    event SuspendedUser(address indexed creator, bool suspended);
    event RemovedUser(address indexed creator, bool deleted);

    event PaymentMade(
        address indexed recipient,
        address payer,
        uint256 amount,
        LibDiamond.PaymentType indexed paymentType,
        uint256 indexed badgeModelId,
        string controllerName
    );

    /**
     * @notice Register a new user
     * @param _metadata IPFS url with the metadata of the user
     */
    function registerUser(string memory _metadata, bool _isCompany) public payable {
        LibDiamond.DiamondStorage storage diamondStorage = LibDiamond.diamondStorage();
        LibDiamond.User storage user = diamondStorage.registeredUsers[_msgSender()];
        if (bytes(user.metadata).length != 0) {
            revert LibTheBadgeUsers.TheBadge__registerUser_alreadyRegistered();
        }

        uint256 registerUserProtocolFee = LibDiamond.getRegisterUserProtocolFee();
        if (msg.value != registerUserProtocolFee) {
            revert LibTheBadgeUsers.TheBadge__registerUser_wrongValue();
        }
        if (msg.value > 0) {
            address feeCollector = LibDiamond.getFeeCollector();
            payable(feeCollector).transfer(msg.value);
            emit PaymentMade(
                feeCollector,
                _msgSender(),
                msg.value,
                LibDiamond.PaymentType.UserRegistrationFee,
                0,
                "0x"
            );
        }

        user.metadata = _metadata;
        user.isCompany = _isCompany;
        user.isCreator = false;
        user.suspended = false;
        user.initialized = true;

        emit LibTheBadgeUsers.UserRegistered(_msgSender(), user.metadata);
    }

    /**
     * @notice Given an user and new metadata, updates the metadata of the user
     * @param _user user address
     * @param _metadata IPFS url
     */
    function updateUser(address _user, string memory _metadata) public onlyRole(DEFAULT_ADMIN_ROLE) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.User storage user = ds.registeredUsers[_user];

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        if (bytes(_metadata).length > 0) {
            user.metadata = _metadata;
        }

        emit UpdatedUserMetadata(_user, _metadata);
    }

    function suspendUser(address _user, bool suspended) public onlyRole(PAUSER_ROLE) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.User storage user = ds.registeredUsers[_user];

        if (bytes(user.metadata).length == 0) {
            revert LibTheBadgeUsers.TheBadge__updateUser_notFound();
        }

        user.suspended = suspended;
        emit SuspendedUser(_user, suspended);
    }

    // TODO CONTINUE WITH ALL THESE OTHER METHODS

    //    /**
    //     * @notice Creates a request to Verify an user in an specific badgeModelController
    //     * @param evidenceUri IPFS uri with the evidence required for the verification
    //     */
    //    function submitUserVerification(
    //        string memory controllerName,
    //        string memory evidenceUri
    //    ) public payable onlyRegisteredUser(_msgSender()) existingBadgeModelController(controllerName) {
    //        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
    //        User storage user = registeredUsers[_msgSender()];
    //
    //        // The verification fee differs in each controller
    //        uint256 verifyCreatorProtocolFee = IBadgeModelController(_badgeModelController.controller)
    //            .getVerifyUserProtocolFee();
    //
    //        if (msg.value != verifyCreatorProtocolFee) {
    //            revert TheBadge__verifyUser_wrongValue();
    //        }
    //
    //        if (msg.value > 0) {
    //            // Transfers the verification fee to the collector
    //            (bool verifyCreatorProtocolFeeSent, ) = payable(feeCollector).call{ value: msg.value }("");
    //            if (verifyCreatorProtocolFeeSent == false) {
    //                revert TheBadge__verifyUser_verificationProtocolFeesPaymentFailed();
    //            }
    //            emit PaymentMade(feeCollector, _msgSender(), msg.value, PaymentType.UserVerificationFee, 0, controllerName);
    //        }
    //
    //        IBadgeModelController(_badgeModelController.controller).submitUserVerification(
    //            _msgSender(),
    //            user.metadata,
    //            evidenceUri
    //        );
    //        emit UserVerificationRequested(_msgSender(), evidenceUri, controllerName);
    //    }
    //
    //    /**
    //     * @notice Creates a request to Verify an user in an specific badgeModelController
    //     * @param _user user address to verify
    //     * @param controllerName id of the controller to execute the verification
    //     * @param verify true if the user should be verified, false otherwise
    //     */
    //    function executeUserVerification(
    //        address _user,
    //        string memory controllerName,
    //        bool verify
    //    ) public onlyRole(VERIFIER_ROLE) existingBadgeModelController(controllerName) onlyRegisteredUser(_user) {
    //        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
    //        IBadgeModelController(_badgeModelController.controller).executeUserVerification(_user, verify);
    //        emit UserVerificationExecuted(_user, controllerName, verify);
    //    }
    //
    //    function getVerificationFee(
    //        string memory controllerName
    //    ) public view existingBadgeModelController(controllerName) returns (uint256) {
    //        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
    //        return IBadgeModelController(_badgeModelController.controller).getVerifyUserProtocolFee();
    //    }
    //
    //    function isUserVerified(
    //        address _user,
    //        string memory controllerName
    //    ) public view existingBadgeModelController(controllerName) returns (bool) {
    //        BadgeModelController storage _badgeModelController = badgeModelControllers[controllerName];
    //        return IBadgeModelController(_badgeModelController.controller).isUserVerified(_user);
    //    }
}
