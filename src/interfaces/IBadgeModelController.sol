// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IBadgeModelController {
    // Write
    function createBadgeModel(address callee, uint256 badgeModelId, bytes calldata data) external;

    function mint(
        address callee,
        uint256 badgeModelId,
        uint256 badgeId,
        bytes calldata data,
        address destinationAddress
    ) external payable returns (uint256);

    function claim(uint256 badgeId, bytes calldata data, address caller) external returns (address);

    function challenge(uint256 badgeId, bytes calldata data, address caller) external payable;

    function removeItem(uint256 badgeId, bytes calldata data, address caller) external payable;

    function submitEvidence(uint256 badgeId, bytes calldata data, address caller) external;

    // Write methods
    function submitUserVerification(address _user, string memory userMetadata, string memory evidenceUri) external;

    function executeUserVerification(address _user, bool verify) external;

    function updateVerifyUserProtocolFee(uint256 _verifyUserProtocolFee) external;

    // Read
    function mintValue(uint256 badgeModelId) external view returns (uint256);

    function isMintableToController(uint256 badgeModelId, address account) external view returns (bool);

    function isClaimable(uint256 badgeId) external view returns (bool);

    function isAssetActive(uint256 badgeId) external view returns (bool);

    function getChallengeDepositValue(uint256 badgeId) external view returns (uint256);

    function getRemovalDepositValue(uint256 badgeId) external view returns (uint256);

    function getVerifyUserProtocolFee() external view returns (uint256);

    function isUserVerified(address _user) external view returns (bool);

    function isBadgeModelMetadataUpgradeable() external view returns (bool);

    function isBadgeModelMetadataUpdatable() external view returns (bool);
}
