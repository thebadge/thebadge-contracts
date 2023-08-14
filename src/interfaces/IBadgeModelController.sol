// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface IBadgeModelController {
    function createBadgeModel(uint256 badgeModelId, bytes calldata data) external;

    function mint(
        address callee,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data
    ) external payable returns (uint256);

    function claim(uint256 badgeId) external;

    function mintValue(uint256 badgeModelId) external view returns (uint256);

    function canMint(uint256 badgeModelId, address account) external view returns (bool);

    function isAssetActive(uint256 badgeId) external view returns (bool);
}
