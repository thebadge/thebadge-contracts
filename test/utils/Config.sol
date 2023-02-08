// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol";

import { TheBadge } from "../../src/TheBadge.sol";
import { KlerosBadgeTypeController } from "../../src/badgeTypeControllers/kleros.sol";
import { BadgeStatus } from "../../src/utils.sol";

contract Config is Test {
    address public deployer;

    uint256 public adminKey = 1;
    address public admin = vm.addr(1);

    uint256 public vegetaKey = 2;
    address public vegeta = vm.addr(2);

    uint256 public gokuKey = 3;
    address public goku = vm.addr(3);

    uint256 public feeCollectorKey = 4;
    address public feeCollector = vm.addr(4);

    uint256 public offChainStrategyFee = 0 ether;

    uint256 oneYear = 60 * 60 * 24 * 365;

    TheBadge public theBadge;
    KlerosBadgeTypeController public klerosController;

    // GBC:
    address lightGTCRFactory = 0x08e58Bc26CFB0d346bABD253A1799866F269805a;
    address klerosArbitror = 0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002;

    // Goerli
    //address lightGTCRFactory = 0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314;
    //address klerosArbitror = 0x1128eD55ab2d796fa92D2F8E1f336d745354a77A;

    constructor() {
        vm.deal(admin, 100 ether);
        vm.deal(admin, 100 ether);
        vm.deal(vegeta, 100 ether);
        vm.deal(goku, 100 ether);
        vm.deal(feeCollector, 100 ether);

        theBadge = new TheBadge();
        theBadge.initialize(admin, feeCollector);

        klerosController = new KlerosBadgeTypeController();
        klerosController.initialize(address(theBadge), klerosArbitror, lightGTCRFactory);

        vm.prank(admin);
        theBadge.setBadgeTypeController("kleros", address(klerosController));
    }

    function getBaseBadgeType() public view returns (TheBadge.CreateBadgeType memory) {
        TheBadge.CreateBadgeType memory badgeType = TheBadge.CreateBadgeType(
            "ipfs/metadataForBadge.json",
            "kleros",
            0,
            0,
            oneYear
        );
        return badgeType;
    }

    function _bytesToAddress(bytes memory bys) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}
