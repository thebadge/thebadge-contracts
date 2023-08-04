// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../interfaces/IBadgeController.sol";
import "./KleroBadgeModelControllerStore.sol";

contract KlerosBadgeModelController is Initializable, IBadgeController, KlerosBadgeModelControllerStore {
    using CappedMath for uint256;
    /**
     * =========================
     * Methods
     * =========================
     */

    function initialize(address _theBadge, address _arbitrator, address _tcrFactory) public initializer {
        theBadge = TheBadge(payable(_theBadge));
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param badgeModelId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    function createBadgeModel(uint256 badgeModelId, bytes calldata data) public onlyTheBadge {
        // TODO: set TCR admin to an address that we control, so we can call "removeItem"

        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        if (_klerosBadgeModel.tcrList != address(0)) {
            revert KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tcrFactory);

        CreateBadgeModel memory args = abi.decode(data, (CreateBadgeModel));

        lightGTCRFactory.deploy(
            IArbitrator(arbitrator),
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)),
            address(0), // TODO: check this.
            args.registrationMetaEvidence,
            args.clearingMetaEvidence,
            args.governor,
            args.baseDeposits,
            args.challengePeriodDuration,
            args.stakeMultipliers,
            args.admin
        );

        // Get the address for the kleros badge model created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();
        }

        klerosBadgeModel[badgeModelId] = KlerosBadgeModel(klerosTcrListAddress);

        emit NewKlerosBadgeModel(badgeModelId, klerosTcrListAddress, args.registrationMetaEvidence);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros controller
     * It sums kleros base deposit + kleros arbitration cost
     */
    function mintValue(uint256 badgeModelId) public view returns (uint256) {
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);

        uint256 arbitrationCost = arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Badge can be minted if it was never requested for the address or if it has a due date before now
     */
    function canMint(uint256, address) public pure returns (bool) {
        return true;
    }

    /**
     * @notice mint badge for kleros controller
     */
    // TODO: should this use public onlyTheBadge?
    function mint(address callee, uint256 badgeModelId, uint256 badgeId, bytes calldata data) public payable {
        // check value
        uint256 mintCost = mintValue(badgeModelId);
        if (msg.value != mintCost) {
            revert KlerosBadgeModelController__mintBadge_wrongValue();
        }

        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        MintParams memory args = abi.decode(data, (MintParams));

        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        // save deposit amount for callee as it has to be returned if it was not challenged.
        bytes32 klerosItemID = keccak256(abi.encodePacked(args.evidence));
        klerosBadge[badgeId] = KlerosBadge(klerosItemID, callee, msg.value);

        emit mintKlerosBadge(badgeId, args.evidence);
    }

    /**
     * @notice get the arbitration cost for a submission or a remove. If the badge is in other state it will return wrong information
     * @param badgeId the badge id
     */
    function getChallengeValue(uint256 badgeId) public view returns (uint256) {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];
        (uint256 badgeModelId, , ) = theBadge.badge(badgeId);
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);

        (, , uint120 requestCount) = lightGeneralizedTCR.items(_klerosBadge.itemID);
        uint256 lastRequestIndex = requestCount - 1;

        (, , , , , , , , bytes memory requestArbitratorExtraData, ) = lightGeneralizedTCR.getRequestInfo(
            _klerosBadge.itemID,
            lastRequestIndex
        );

        uint256 arbitrationCost = arbitrator.arbitrationCost(requestArbitratorExtraData);

        uint256 challengerBaseDeposit = lightGeneralizedTCR.submissionChallengeBaseDeposit();

        // TODO: fix this. as TCR using itemID
        // theBadge.badge(badgeId, account).status == BadgeStatus.InReview
        //     ? lightGeneralizedTCR.submissionChallengeBaseDeposit()
        //     : lightGeneralizedTCR.removalChallengeBaseDeposit();

        return arbitrationCost.addCap(challengerBaseDeposit);
    }

    /**
     * @notice claim a badge from a TCR list
     * b. Transfers deposit to badge's callee
     * c. Sets badge's callee deposit to 0
     */
    function claim(uint256 badgeId) public payable {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];
        (uint256 badgeModelId, , ) = theBadge.badge(badgeId);
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        if (_klerosBadge.deposit > address(this).balance) {
            revert KlerosBadgeModelController__claimBadge_insufficientBalance();
        }

        uint256 balanceToDeposit = _klerosBadge.deposit;
        _klerosBadge.deposit = 0;
        payable(_klerosBadge.callee).transfer(balanceToDeposit);
    }

    function isAssetActive(uint256 badgeId) public view returns (bool) {
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId];
        (uint256 badgeModelId, , ) = theBadge.badge(badgeId);
        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];

        if (_klerosBadgeModel.tcrList != address(0)) {
            ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
            (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
            if (klerosItemStatus == 1 || klerosItemStatus == 3) {
                return true;
            }
        }
        // TODO: should this check the badge dueDate?
        return false;
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
