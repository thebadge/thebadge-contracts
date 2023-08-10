// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface ITheBadge is IERC1155Upgradeable {
    function mint(uint256 badgeModelId, address account, string memory tokenURI, bytes memory data) external payable;

    function balanceOf(address account, uint256 badgeId) external view returns (uint256);

    function balanceOfBadgeModel(address account, uint256 badgeModelId) external view returns (uint256);

    function isExpired(uint256 badgeId) external view returns (bool);

    function updateMintBadgeDefaultProtocolFee(uint256 _mintBadgeDefaultFee) external;

    function updateCreateBadgeModelProtocolFee(uint256 _createBadgeModelValue) external;

    function updateRegisterCreatorProtocolFee(uint256 _registerCreatorValue) external;

    function pause() external;

    function unpause() external;

    function uri(uint256 badgeId) external view returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
