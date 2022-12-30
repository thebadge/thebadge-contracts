// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ILightGeneralizedTCR } from "../interfaces/ILightGeneralizedTCR.sol";
import { ILightGTCRFactory } from "../interfaces/ILightGTCRFactory.sol";
import { IArbitrator } from "../../lib/erc-792/contracts/IArbitrator.sol";
import "../../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

import "../interfaces/IBadgeController.sol";
import "../interfaces/ITheBadge.sol";

// TODO: make this upgradable
// TODO: only callable from TheBadge contract
contract KlerosBadgeTypeController is Initializable, IBadgeController {
    ITheBadge public theBadge;
    IArbitrator public arbitrator;
    address public tcrFactory;

    /**
     * Struct to use as args to create a Kleros badge type strategy.
     *  @param badgeMetadata IPFS uri for the badge
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
    struct CreateBadgeType {
        string badgeMetadata;
        address governor;
        address admin;
        uint256 courtId;
        uint256 numberOfJurors;
        string registrationMetaEvidence;
        string clearingMetaEvidence;
        uint256 challengePeriodDuration;
        uint256[4] baseDeposits;
        uint256[3] stakeMultipliers;
        uint256 mintCost; // TODO: rename to value
        uint256 validFor; // how many days an asset is valid after being minted. if 0 then is valid forever.
    }

    struct RequestBadgeData {
        string evidence;
    }

    /**
     * @param tcrList The TCR List created for a particular badge type
     */
    struct KlerosBadgeType {
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

    /**
     * @notice Kleros's badge information.
     * badgeId => KlerosBadgeInfo
     */
    mapping(uint256 => KlerosBadgeType) public klerosBadgeType;

    /**
     * @notice Information related to a specific asset from a kleros strategy
     * badgeId => address => KlerosAssetInfo
     */
    mapping(uint256 => mapping(address => KlerosBadge)) public klerosBadge;

    /**
     * =========================
     * Events
     * =========================
     */
    event NewKlerosStrategy(
        uint256 indexed strategyId,
        address indexed klerosTCRAddress,
        string metadata,
        string registrationMetadata
    );
    event MintKlerosBadge(address indexed callee, uint256 indexed badgeTypeId, address indexed to, string evidence);

    /**
     * =========================
     * Errors
     * =========================
     */
    error KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
    error KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
    error KlerosBadgeTypeController__mintBadge_alreadyMinted();
    error KlerosBadgeTypeController__mintBadge_wrongBadgeType();
    error KlerosBadgeTypeController__mintBadge_isPaused();
    error KlerosBadgeTypeController__mintBadge_wrongValue();
    error KlerosBadgeTypeController__claimBadge_insufficientBalance();
    error KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();

    /**
     * =========================
     * Modifiers
     * =========================
     */

    modifier onlyTheBadge() {
        if (address(theBadge) != msg.sender) {
            revert KlerosBadgeTypeController__onlyTheBadge_senderNotTheBadge();
        }
        _;
    }

    function initialize(address _theBadge, address _arbitrator, address _tcrFactory) public initializer {
        theBadge = ITheBadge(_theBadge);
        arbitrator = IArbitrator(_arbitrator);
        tcrFactory = _tcrFactory;
    }

    /**
     * @notice Allows to create off-chain kleros strategies for registered entities
     * @param badgeId BadgeId from TheBadge contract
     * @param data Encoded data required to create a Kleros TCR list
     */
    function createBadgeType(uint256 badgeId, bytes calldata data) public payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        if (_klerosBadgeType.tcrList != address(0)) {
            revert KlerosBadgeTypeController__createBadgeType_badgeTypeAlreadyCreated();
        }

        ILightGTCRFactory lightGTCRFactory = ILightGTCRFactory(tcrFactory);

        CreateBadgeType memory args = abi.decode(data, (CreateBadgeType));

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
            revert KlerosBadgeTypeController__createBadgeType_TCRListAddressZero();
        }

        klerosBadgeType[badgeId] = KlerosBadgeType(klerosTcrListAddress);

        emit NewKlerosStrategy(badgeId, klerosTcrListAddress, args.badgeMetadata, args.registrationMetaEvidence);
    }

    /**
     * @notice Returns the cost for minting a badge for a kleros strategy
     * It sums kleros base deposit + kleros arbitration cost
     */
    function badgeRequestValue(uint256 badgeId) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);

        uint256 arbitrationCost = arbitrator.arbitrationCost(lightGeneralizedTCR.arbitratorExtraData());
        uint256 baseDeposit = lightGeneralizedTCR.submissionBaseDeposit();

        return arbitrationCost + baseDeposit;
    }

    /**
     * @notice Badge can be minted if it was never requested for the address or if it has a due date before now
     */
    function canRequestBadge(uint256 _badgeId, address _account) public view returns (bool) {
        ITheBadge.Badge memory _badge = theBadge.badge(_badgeId, _account);

        if (_badge.dueDate == 0 && (_badge.status == BadgeStatus.InReview || _badge.status == BadgeStatus.Approved)) {
            return false;
        }

        if (_badge.dueDate > 0 && block.timestamp < _badge.dueDate) {
            return false;
        }

        return true;
    }

    /**
     * @notice mint badge for kleros strategy
     */
    function requestBadge(address callee, uint256 badgeId, address account, bytes calldata data) public payable {
        uint256 mintCost = badgeRequestValue(badgeId);
        if (msg.value != mintCost) {
            revert KlerosBadgeTypeController__mintBadge_wrongValue();
        }

        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        RequestBadgeData memory args = abi.decode(data, (RequestBadgeData));

        // save deposit amount for callee as it has to be returned if it was not challenged.
        lightGeneralizedTCR.addItem{ value: (msg.value) }(args.evidence);

        klerosBadge[badgeId][account] = KlerosBadge(keccak256(abi.encodePacked(args.evidence)), callee, msg.value);
        emit MintKlerosBadge(callee, badgeId, account, args.evidence);
    }

    /**
     * @notice claim a badge from a TCR list
     * a. Marks asset as Approved
     * b. Transfers deposit to badge's callee
     * c. Sets badge's callee deposit to 0
     */
    function claimBadge(uint256 badgeId, address account) public payable {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
        lightGeneralizedTCR.executeRequest(_klerosBadge.itemID);

        theBadge.updateBadgeStatus(badgeId, account, BadgeStatus.Approved);

        if (_klerosBadge.deposit > address(this).balance) {
            revert KlerosBadgeTypeController__claimBadge_insufficientBalance();
        }

        payable(_klerosBadge.callee).transfer(_klerosBadge.deposit);
        _klerosBadge.deposit = 0;
    }

    function balanceOf(uint256 badgeId, address account) public view returns (uint256) {
        KlerosBadgeType storage _klerosBadgeType = klerosBadgeType[badgeId];
        KlerosBadge storage _klerosBadge = klerosBadge[badgeId][account];

        if (_klerosBadgeType.tcrList != address(0)) {
            ILightGeneralizedTCR lightGeneralizedTCR = ILightGeneralizedTCR(_klerosBadgeType.tcrList);
            (uint8 klerosItemStatus, , ) = lightGeneralizedTCR.getItemInfo(_klerosBadge.itemID);
            if (klerosItemStatus == 1 || klerosItemStatus == 3) {
                return 1;
            }
        }

        return 0;
    }

    /**
     * @notice we need a receive function to receive deposits devolution from kleros
     */
    receive() external payable {}
}
