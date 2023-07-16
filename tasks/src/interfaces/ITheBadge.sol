// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ITheBadge {
    struct Badge {
        uint256 dueDate;
    }

    function badge(uint256 _badgeId, address _account) external view returns (Badge memory);
}
