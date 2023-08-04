// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ITheBadge {
    function mint(uint256 badgeModelId, address account, string memory tokenURI, bytes memory data) external payable;

    function balanceOf(address account, uint256 badgeId) external view returns (uint256);

    function updateProtocolValues(
        uint256 _mintBadgeDefaultFee,
        uint256 _createBadgeModelValue,
        uint256 _registerCreatorValue
    ) external;

    function pause() external;

    function unpause() external;

    function uri(uint256 badgeId) external view returns (string memory);
}
