// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface ITheBadgeUsers {
    // Write methods
    function registerUser(string memory _metadata, bool _isCompany) external payable;

    function updateProfile(string memory _metadata) external;

    function updateUser(address _creator, string memory _metadata) external;

    function suspendUser(address _creator, bool suspended) external;

    function submitUserVerification(string memory controllerName, string memory evidenceUri) external payable;

    function executeUserVerification(address _user, string memory controllerName, bool verify) external;

    function isUserVerified(address _user, string memory controllerName) external view returns (bool);

    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) external;

    function getVerificationFee(string memory controllerName) external view returns (uint256);
}
