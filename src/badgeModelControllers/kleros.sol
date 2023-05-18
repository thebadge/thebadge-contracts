// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../interfaces/ILightGTCRFactory.sol";
import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";

import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IBadgeController.sol";
import { TheBadge } from "../TheBadge.sol";
import "../utils/CappedMath.sol";

contract KlerosController is Initializable, IBadgeController {
    TheBadge public theBadge;
    IArbitrator public arbitrator;
    address public tcrFactory;

    using CappedMath for uint256;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param governor An address with permission to updates parameters of the list. Use Kleros governor for full decentralization.
     *  @param admin The address with permission to add/remove items directly.
     *  @param courtId The ID of the kleros's court.
     *  @param numberOfJurors The number of jurors required if a dispute is initiated.
     *  @param registrationMetaEvidence The URI of the meta evidence object for registration requests.
     *  @param clearingMetaEvidence The URI of the meta evidence object for clearing requests.
     *  @param challengePeriodDuration The time in seconds parties have to challenge a request.
     *  @param baseDeposits The base deposits for requests/challenges as follows:
     *  - The base deposit to submit an item.
     *  - The base deposit to remove an item.
     *  - The base deposit to challenge a submission.
     *  - The base deposit to challenge a removal request.
     *  @param stakeMultipliers Multipliers of the arbitration cost in basis points (see GeneralizedTCR MULTIPLIER_DIVISOR) as follows:
     *  - The multiplier applied to each party's fee stake for a round when there is no winner/loser in the previous round (e.g. when it's the first round or the arbitrator refused to arbitrate).
     *  - The multiplier applied to the winner's fee stake for an appeal round.
     *  - The multiplier applied to the loser's fee stake for an appeal round.
     * @param mintCost The cost for minting a badge, it goes to the emitter.
     * @param validFor The time in seconds of how long the badge is valid. (cero for infinite)
     */
    struct CreateBadgeModel {
        address governor;
        address admin;
        uint256 courtId;
        uint256 numberOfJurors;
        string registrationMetaEvidence;
        string clearingMetaEvidence;
        uint256 challengePeriodDuration;
        uint256[4] baseDeposits;
        uint256[3] stakeMultipliers;
    }

    struct MintParams {
        string evidence;
    }

    /**
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeModel {
        address tcrList;
    }

    /**
     * @param itemID internal Kleros TCR list ID
     * @param callee address paying the deposit
     * @param deposit the deposit amount
     */
    struct KlerosBadge {
        bytes32 itemID;
        address callee;
        uint256 deposit;
    }

    /**
     * =========================
     * Store
     * =========================
     */

    mapping(uint256 => KlerosBadgeModel) public klerosBadgeModel;
    mapping(uint256 => KlerosBadge) public klerosBadge;

    /**
     * =========================
     * Events
     * =========================
     */
    event NewKlerosBadgeModel(uint256 indexed badgeModelId, address indexed tcrAddress, string metadataUri);
    event mintKlerosBadge(uint256 indexed badgeId, string evidence);
    event KlerosBadgeChallenged(uint256 indexed badgeId, address indexed wallet, string evidence, address sender);

    /**
     * =========================
     * Errors
     * =========================
     */
    error KlerosBadgeModelController__createBadgeModel_badgeModelAlreadyCreated();
    error KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeModelController__mintBadge_alreadyMinted();
    error KlerosBadgeModelController__mintBadge_wrongBadgeModel();
    error KlerosBadgeModelController__mintBadge_isPaused();
    error KlerosBadgeModelController__mintBadge_wrongValue();
    error KlerosBadgeModelController__claimBadge_insufficientBalance();
    error KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert KlerosBadgeModelController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

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

        // Get the address for the strategy created
        uint256 index = lightGTCRFactory.count() - 1;
        address klerosTcrListAddress = address(lightGTCRFactory.instances(index));
        if (klerosTcrListAddress == address(0)) {
            revert KlerosBadgeModelController__createBadgeModel_TCRListAddressZero();
        }

        klerosBadgeModel[badgeModelId] = KlerosBadgeModel(klerosTcrListAddress);

        emit NewKlerosBadgeModel(badgeModelId, klerosTcrListAddress, args.registrationMetaEvidence);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros strategy
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
     * @notice mint badge for kleros strategy
     */
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

        return false;
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
