// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils.sol";

interface IBadgeController {
    function createBadgeType(uint256 badgeId, bytes calldata data) external payable;

    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) external payable;

    function claimBadge(uint256 badgeId, address account) external payable;

    function badgeRequestValue(uint256 badgeId) external view returns (uint256);

    function canRequestBadge(uint256 badgeId, address account) external view returns (bool);

    function balanceOf(uint256 badgeId, address account) external view returns (uint256);
}
