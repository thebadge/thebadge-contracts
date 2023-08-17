// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ITheBadgeUsers {
    // Write methods
    function registerUser(string memory _metadata, bool _isCompany) external payable;

    function updateUser(address _creator, string memory _metadata) external;

    function suspendUser(address _creator, bool suspended) external;

    function removeUser() external; // Method not implemented

    function submitUserVerification(string memory controllerName, string memory evidenceUri) external payable;

    function executeUserVerification(address _user, string memory controllerName, bool verify) external; // TODO Only called by ROLE_VERIFICATOR
}
