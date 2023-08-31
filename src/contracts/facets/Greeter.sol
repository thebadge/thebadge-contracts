pragma solidity ^0.8.0;

import { LibDiamond } from "../libraries/LibDiamond.sol";

contract Greeter {
    function facetGetGreeting() external view returns (string memory) {
        return LibDiamond.getGreeting();
    }

    function facetSetGreeting(string memory _greeting) external {
        return LibDiamond.setGreeting(_greeting);
    }
}
