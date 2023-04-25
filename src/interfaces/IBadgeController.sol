// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBadgeController {
    function createBadgeType(uint256 badgeId, bytes calldata data) external;

    function balanceOf(uint256 badgeTypeId, address account) external view returns (uint256);

    function canRequestBadge(uint256 badgeTypeId, address account) external view returns (bool);

    function badgeRequestValue(uint256 badgeTypeId) external view returns (uint256);

    function requestBadge(address callee, uint256 badgeTypeId, address account, bytes calldata data) external payable;

    function claimBadge(uint256 badgeId, address account) external payable;
}
