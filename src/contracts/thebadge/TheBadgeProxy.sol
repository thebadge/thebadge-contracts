// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;
/**
 * =========================
 * Serves as a reverse-proxy for all the TheBadge contracts
 * =========================
 */

import { TheBadgeRoles } from "./TheBadgeRoles.sol";
import { LibTheBadge } from "../libraries/LibTheBadge.sol";
import { CountersUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ITheBadgeProxy } from "../../interfaces/ITheBadgeProxy.sol";

contract TheBadgeProxy is TheBadgeRoles, OwnableUpgradeable, ITheBadgeProxy {
    address public theBadge;
    address public theBadgeModels;
    address public theBadgeUsers;
    // Allows to use current() and increment() for badgeModelIds or badgeIds
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// @custom:oz-upgrades-unsafe-allow constructor
    // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#initialization
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address admin,
        address _theBadge,
        address _theBadgeModels,
        address _theBadgeUsers
    ) public initializer {
        __Ownable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        theBadge = _theBadge;
        theBadgeModels = _theBadgeModels;
        theBadgeUsers = _theBadgeUsers;
    }

    function setTheBadge(address _theBadge) public onlyRole(DEFAULT_ADMIN_ROLE) {
        theBadge = _theBadge;
    }

    function setTheBadgeModels(address _theBadgeModels) public onlyRole(DEFAULT_ADMIN_ROLE) {
        theBadgeModels = _theBadgeModels;
    }

    function setTheBadgeUsers(address _theBadgeUsers) public onlyRole(DEFAULT_ADMIN_ROLE) {
        theBadgeUsers = _theBadgeUsers;
    }

    // Fallback function to delegate calls to the target contracts
    fallback() external payable {
        address targetContract;
        assembly {
            // Load the first 32 bytes of the call data (function selector)
            let calldataPtr := mload(0x40)
            // Set the target contract based on the first four bytes of the call data
            targetContract := calldataload(calldataPtr)
        }

        if (targetContract == theBadgeUsers) {
            // Call the user contract using delegatecall
            (bool success, ) = theBadgeUsers.delegatecall(msg.data);
            if (!success) {
                revert LibTheBadge.TheBadge__theBadgeUsers_method_execution_failed();
            }
        } else if (targetContract == theBadgeModels) {
            // Call the models contract using delegatecall
            (bool success, ) = theBadgeModels.delegatecall(msg.data);
            if (!success) {
                revert LibTheBadge.TheBadge__theBadgeModels_method_execution_failed();
            }
        } else if (targetContract == theBadge) {
            // Call the badge contract using delegatecall
            (bool success, ) = theBadge.delegatecall(msg.data);
            if (!success) {
                revert LibTheBadge.TheBadge__theBadge_method_execution_failed();
            }
        } else {
            revert LibTheBadge.TheBadge__proxy_method_not_supported();
        }
    }

    // tslint:disable-next-line:no-empty
    receive() external payable {}
}
