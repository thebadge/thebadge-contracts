pragma solidity ^0.8.20;

import { TheBadgeStore } from "../../src/contracts/thebadge/TheBadgeStore.sol";
import "../../src/contracts/libraries/LibTheBadgeStore.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Config } from "./Config.sol";

contract AddPermittedContract is Config {
    event ContractAdded(string indexed _contractName, address indexed contractAddress);
    bytes32 adminRole = 0x00;

    function testWorks() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        string memory contractName = "ContractName";
        address contractAddress = vm.addr(11);

        vm.prank(u1);
        vm.expectEmit(true, true, false, true);
        emit ContractAdded(contractName, contractAddress);
        badgeStore.addPermittedContract(contractName, contractAddress);

        assertEq(badgeStore.allowedContractAddressesByContractName(contractName), contractAddress);
        assertEq(badgeStore.allowedContractAddresses(contractAddress), true);
    }

    function testRevertsWhenNoAdminRole() public {
        string memory contractName = "ContractName";
        address contractAddress = vm.addr(11);

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
        badgeStore.addPermittedContract(contractName, contractAddress);
    }

    function testRevertsWhenZeroAddress() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        string memory contractName = "ContractName";
        address contractAddress = address(0);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_InvalidContractAddress.selector);
        badgeStore.addPermittedContract(contractName, contractAddress);
    }

    function testRevertsWhenAlreadyExist() public {
        vm.prank(admin);
        badgeStore.grantRole(adminRole, u1);

        string memory contractName = "ContractName";
        address contractAddress = vm.addr(11);

        vm.prank(u1);
        badgeStore.addPermittedContract(contractName, contractAddress);

        vm.prank(u1);
        vm.expectRevert(LibTheBadgeStore.TheBadge__Store_ContractNameAlreadyExists.selector);
        badgeStore.addPermittedContract(contractName, contractAddress);
    }
}
