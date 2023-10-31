pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";
import { Config } from "./Config.sol";

contract UpdatePermittedContract is Config {
    event ContractUpdated(string indexed _contractName, address indexed contractAddress);
    bytes32 adminRole = 0x00;

    function testWorks() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        string memory contractName = "ContractName";
        address contractAddress = vm.addr(11);
        address newContractAddress = vm.addr(12);

        vm.prank(u1);
        badgeStore.addPermittedContract(contractName, contractAddress);

        vm.prank(u1);
        vm.expectEmit(true, true, false, true);
        emit ContractUpdated(contractName, newContractAddress);
        badgeStore.updatePermittedContract(contractName, newContractAddress);

        assertEq(badgeStore.allowedContractAddressesByContractName(contractName), newContractAddress);
        assertEq(badgeStore.allowedContractAddresses(newContractAddress), true);
        assertEq(badgeStore.allowedContractAddresses(contractAddress), false);
    }

    function testRevertsWhenNoAdminRole() public {
        vm.expectRevert(
            abi.encodeWithSelector(IAccessControl.AccessControlUnauthorizedAccount.selector, u1, adminRole)
        );
        vm.prank(u1);
        badgeStore.updatePermittedContract("ContractName", vm.addr(12));
    }

    function testRevertsWhenZeroAddress() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_InvalidContractAddress.selector);
        badgeStore.updatePermittedContract("ContractName", address(0));
    }

    function testRevertsWhenNoExist() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_InvalidContractName.selector);
        badgeStore.updatePermittedContract("ContractName", vm.addr(11));
    }
}
