// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "forge-std/Test.sol";

import "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

import { TheBadge } from "../../src/contracts/thebadge/TheBadge.sol";
import { TheBadgeLogic } from "../../src/contracts/thebadge/TheBadgeLogic.sol";
import { KlerosController } from "../../src/contracts/badgeModelControllers/klerosBadgeModelController.sol";

contract Config is Test {
    address public admin = vm.addr(1);
    address public vegeta = vm.addr(2);
    address public goku = vm.addr(3);
    address public feeCollector = vm.addr(4);
    address public minter = vm.addr(5);
    address public creator = vm.addr(6);

    uint256 public offChainStrategyFee = 0 ether;

    uint256 oneYear = 60 * 60 * 24 * 365;

    TheBadge public theBadge;
    KlerosController public klerosController;

    // GBC:
    address lightGTCRFactory = 0x08e58Bc26CFB0d346bABD253A1799866F269805a;
    address klerosArbitror = 0x9C1dA9A04925bDfDedf0f6421bC7EEa8305F9002;

    // Goerli
    //address lightGTCRFactory = 0x55A3d9Bd99F286F1817CAFAAB124ddDDFCb0F314;
    //address klerosArbitror = 0x1128eD55ab2d796fa92D2F8E1f336d745354a77A;

    constructor() {
        vm.deal(admin, 100 ether);
        vm.deal(vegeta, 100 ether);
        vm.deal(goku, 100 ether);
        vm.deal(minter, 100 ether);
        vm.deal(feeCollector, 100 ether);
        vm.deal(creator, 100 ether);

        address imp = address(new TheBadge());
        address proxy = ClonesUpgradeable.clone(imp);
        theBadge = TheBadge(payable(proxy));
        theBadge.initialize(admin, feeCollector, minter);

        klerosController = new KlerosController();
        klerosController.initialize(address(theBadge), klerosArbitror, lightGTCRFactory);

        vm.prank(admin);
        theBadge.setBadgeModelController("kleros", address(klerosController));
    }

    function getBaseBadgeModel() public view returns (TheBadge.CreateBadgeModel memory) {
        TheBadge.CreateBadgeModel memory badgeModel = TheBadgeLogic.CreateBadgeModel(
            "ipfs/metadataForBadge.json",
            "kleros",
            0,
            oneYear
        );
        return badgeModel;
    }

    function getKlerosBaseBadgeModel() public pure returns (KlerosController.CreateBadgeModel memory) {
        uint256[4] memory baseDeposits;
        baseDeposits[0] = 0.1 ether;
        baseDeposits[1] = 0.1 ether;
        baseDeposits[2] = 0.1 ether;
        baseDeposits[3] = 0.1 ether;

        uint256[3] memory stakeMultipliers;
        stakeMultipliers[0] = 1;
        stakeMultipliers[1] = 1;
        stakeMultipliers[2] = 1;

        KlerosController.CreateBadgeModel memory strategy = KlerosController.CreateBadgeModel(
            address(0), // governor
            address(0), // admin
            1, // court
            1, // jurors
            "ipfs/registrationMetaEvidence.json",
            "ipfs/clearingMetaEvidence.json",
            100, // challengePeriodDuration
            baseDeposits,
            stakeMultipliers
        );
        return strategy;
    }

    function _bytesToAddress(bytes memory bys) public pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 32))
        }
    }
}
