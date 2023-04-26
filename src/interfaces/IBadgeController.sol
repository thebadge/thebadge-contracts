// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBadgeController {
    function createBadgeType(uint256 badgeTypeId, bytes calldata data) external;

    function isAssetActive(uint256 badgeId) external view returns (bool);

    function canMint(uint256 badgeTypeId, address account) external view returns (bool);

    function mintValue(uint256 badgeTypeId) external view returns (uint256);

    function mint(address callee, uint256 badgeTypeId, uint256 badgeId, bytes calldata data) external payable;

    function claim(uint256 badgeId) external payable;
}
