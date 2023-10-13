// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import { TheBadgeStore } from "../contracts/thebadge/TheBadgeStore.sol";

interface ITheBadgeModels {
    // Write methods
    function addBadgeModelController(string memory controllerName, address controllerAddress) external;

    function createBadgeModel(TheBadgeStore.CreateBadgeModel memory args, bytes memory data) external payable;

    function updateBadgeModel(uint256 badgeModelId, uint256 mintCreatorFee, bool paused) external;

    function suspendBadgeModel() external view; // Method not implemented

    function updateBadgeModelProtocolFee(uint256 badgeModelId, uint256 feeInBps) external;

    function isBadgeModelSuspended(uint256 badgeModelId) external returns (bool);
}
