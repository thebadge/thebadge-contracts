// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../utils/enums.sol";

interface ITheBadge {
    struct Badge {
        BadgeStatus status;
        uint256 dueDate;
    }

    function badge(uint256 _badgeId, address _account) external view returns (Badge memory);

    function updateBadgeStatus(uint256 badgeId, address badgeOwner, BadgeStatus status) external;
}
