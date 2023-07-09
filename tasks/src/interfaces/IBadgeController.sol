// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IBadgeController {
    function createBadgeModel(uint256 badgeModelId, bytes calldata data) external;

    function isAssetActive(uint256 badgeId) external view returns (bool);

    function canMint(uint256 badgeModelId, address account) external view returns (bool);

    function mintValue(uint256 badgeModelId) external view returns (uint256);

    function mint(address callee, uint256 badgeModelId, uint256 badgeId, bytes calldata data) external payable;

    function claim(uint256 badgeId) external payable;
}
