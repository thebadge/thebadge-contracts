// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "./IBadgeModelController.sol";

interface IKlerosBadgeModelController is IBadgeModelController {
    function getChallengeDepositValue(uint256 badgeId) external view returns (uint256);

    function getRemovalDepositValue(uint256 badgeId) external view returns (uint256);
}
