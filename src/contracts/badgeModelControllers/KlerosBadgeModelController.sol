// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../../interfaces/ILightGTCRFactory.sol";

import "../../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../../interfaces/IBadgeModelController.sol";
import "./KleroBadgeModelControllerStore.sol";

contract KlerosBadgeModelController is Initializable, IBadgeModelController, KlerosBadgeModelControllerStore {
    using CappedMath for uint256;

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
            IArbitrator(arbitrator), // Arbitrator address
            bytes.concat(abi.encodePacked(args.courtId), abi.encodePacked(args.numberOfJurors)), // ArbitratorExtraData
            address(0), // TODO: check this. The address of the TCR that stores related TCR addresses. This parameter can be left empty.
            args.registrationMetaEvidence, // The URI of the meta evidence object for registration requests.
            args.clearingMetaEvidence, // The URI of the meta evidence object for clearing requests.
            args.governor, // The trusted governor of this contract.
            args.baseDeposits, // The base deposits for requests/challenges (4 values: submit, remove, challenge and removal request)
            args.challengePeriodDuration, // The time in seconds parties have to challenge a request.
            args.stakeMultipliers, // Multipliers of the arbitration cost in basis points (see LightGeneralizedTCR MULTIPLIER_DIVISOR)
            args.admin // The address of the relay contract to add/remove items directly.
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
     * @notice mints a klerosBadge
     * @param callee the address that called the mint() function, it could be different than the recipient (for instance: it could be a relayer)
     * @param badgeModelId the badgeModelId
     * @param badgeId the klerosBadgeId
     * @param data the klerosBadgeId
     */
    // TODO: should this use public onlyTheBadge? (but it won't allow to have a relayer)
    function mint(address callee, uint256 badgeModelId, uint256 badgeId, bytes calldata data) public payable {
        // check value
        uint256 mintCost = mintValue(badgeModelId);
        if (msg.value != mintCost) {
            revert KlerosBadgeModelController__mintBadge_wrongValue();
        }

        KlerosBadgeModel storage _klerosBadgeModel = klerosBadgeModel[badgeModelId];
        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeModel.tcrList);
        MintParams memory args = abi.decode(data, (MintParams));

        // TODO: it would be good to emit and mintKlerosBadge which the badgeId
        // and the klerosItemID (which can be calculated here, before adding the item in TCR)
        // but could it cause some issues if the item it's not added on the next line?
        // Note: it would be good, as it will simplify a lot the logic on the subgraph, not needing to listen to internal TCR events
        // in order to track the item
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        // Calculates which is the itemID inside the klerosTCR list
        // Its needed on the subgraph to check the disputes status for that item
        bytes32 klerosItemID = keccak256(abi.encodePacked(args.evidence));
        // save deposit amount for callee as it has to be returned if it was not challenged.
        klerosBadge[badgeId] = KlerosBadge(klerosItemID, callee, msg.value);

        emit mintKlerosBadge(badgeId, args.evidence);
    }

    /**
     * @notice After the review period ends, the items on the tcr list should be claimed using this function
     * It Transfers deposit to badge's callee and sets badge's callee deposit to 0
     * @param badgeId the klerosBadgeId
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

    /**
     * @notice Returns the cost for minting a badge for a kleros controller, its the result of doing klerosBaseDeposit + klerosArbitrationCost
     * @param badgeModelId the badgeModelId
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
        // TODO: implementation missing?
        return true;
    }

    /**
     * @notice Checks the status of the badge within the Kleros TCR, returns true if the status is (1 = registered or 3 = clearing/removal requested)
     * It returns false for the other statuses (0 = absent; 2 = registration requested)
     * @param badgeId the klerosBadgeId
     */
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
        // TODO: should this check the badge dueDate?,
        return false;
    }

    /**
     * @notice get the arbitration cost for a submission or a remove. If the badge is in other state it will return wrong information
     * @param badgeId the klerosBadgeId
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
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
