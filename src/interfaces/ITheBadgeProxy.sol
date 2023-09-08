// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

interface ITheBadgeProxy {
    function setTheBadge(address _theBadge) external;

    function setTheBadgeModels(address _theBadgeModels) external;

    function setTheBadgeUsers(address _theBadgeUsers) external;
}
