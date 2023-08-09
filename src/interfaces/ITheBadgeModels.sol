// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../contracts/thebadge/TheBadgeStore.sol";

interface ITheBadgeModels {
    function setBadgeModelController(string memory controllerName, address controllerAddress) external;

    function registerBadgeModelCreator(string memory _metadata) external payable;

    function updateBadgeModelCreator(address _creator, string memory _metadata) external;

    function suspendBadgeModelCreator() external; // Method not implemented

    function removeBadgeModelCreator() external; // Method not implemented

    function createBadgeModel(TheBadgeStore.CreateBadgeModel memory args, bytes memory data) external payable;

    function updateBadgeModel(uint256 badgeModelId, uint256 mintCreatorFee, uint256 validFor, bool paused) external;

    function suspendBadgeModel() external view; // Method not implemented

    function updateBadgeModelFee(uint256 badgeModelId, uint256 feeInBps) external;

    function mintValue(uint256 badgeModelId) external view returns (uint256);
}
