// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { TheBadgeUsersStore } from "../contracts/thebadge/TheBadgeUsersStore.sol";

interface ITheBadgeUsers {
    // Read methods
    function getUser(address _user) external view returns (TheBadgeUsersStore.User memory);

    function getUserVerifyStatus(
        address controllerAddress,
        address userAddress
    ) external view returns (TheBadgeUsersStore.UserVerification memory);

    function getRegisterFee() external view returns (uint256);

    function getVerificationFee(string memory controllerName) external view returns (uint256);

    function isUserVerified(address _user, string memory controllerName) external view returns (bool);

    // Write methods
    function registerUser(string memory _metadata, bool _isCompany) external payable;

    function updateProfile(string memory _metadata) external;

    function updateUser(address _creator, string memory _metadata) external;

    function suspendUser(address _creator, bool suspended) external;

    function makeUserCreator(address _creator) external;

    function submitUserVerification(string memory controllerName, string memory evidenceUri) external payable;

    function executeUserVerification(address _user, string memory controllerName, bool verify) external;

    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) external;
}
