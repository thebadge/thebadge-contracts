// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ITheBadgeUsers {
    // Write methods
    function registerBadgeModelCreator(string memory _metadata) external payable;

    function updateBadgeModelCreator(address _creator, string memory _metadata) external;

    function suspendBadgeModelCreator(address _creator, bool suspended) external;

    function removeBadgeModelCreator() external; // Method not implemented
}
