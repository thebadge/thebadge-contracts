pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Config } from "./Config.sol";

contract RemovePermittedContract is Config {
    event ContractRemoved(string indexed _contractName, address indexed contractAddress);
    bytes32 adminRole = 0x00;

    function testWorks() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        string memory contractName = "ContractName";
        address contractAddress = vm.addr(11);

        vm.prank(u1);
        badgeStore.addPermittedContract(contractName, contractAddress);

        vm.prank(u1);
        vm.expectEmit(true, true, false, true);
        emit ContractRemoved(contractName, contractAddress);
        badgeStore.removePermittedContract(contractName);

        assertEq(badgeStore.allowedContractAddressesByContractName(contractName), address(0));
        assertEq(badgeStore.allowedContractAddresses(contractAddress), false);
    }

    function testRevertsWhenNoAdminRole() public {
        string memory contractName = "ContractName";
        // TODO Fix expect revert message
        //        vm.expectRevert(
        //            abi.encodePacked(
        //                "AccessControl: account ",
        //                Strings.toHexString(u1),
        //                " is missing role ",
        //                Strings.toHexString(uint256(adminRole), 32)
        //            )
        //        );

        vm.expectRevert();
        vm.prank(u1);
        badgeStore.removePermittedContract(contractName);
    }

    function testRevertsWhenNoExist() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_InvalidContractName.selector);
        badgeStore.removePermittedContract("ContractName");
    }
}
