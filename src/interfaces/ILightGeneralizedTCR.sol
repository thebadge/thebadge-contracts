// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/**
 *  @title LightGeneralizedTCR
 *  Aa curated registry for any types of items. Just like a TCR contract it features the request-challenge protocol and appeal fees crowdfunding.
 *  The difference between LightGeneralizedTCR and GeneralizedTCR is that instead of storing item data in storage and event logs,
 *  LightCurate only stores the URI of item in the logs. This makes it considerably cheaper to use and allows more flexibility with the item columns.
 */
interface ILightGeneralizedTCR {
    enum Status {
        Absent, // The item is not in the registry.
        Registered, // The item is in the registry.
        RegistrationRequested, // The item has a request to be added to the registry.
        ClearingRequested // The item has a request to be removed from the registry.
    }

    /**
     * @dev Submit a request to register an item. Accepts enough ETH to cover the deposit, reimburses the rest.
     * @param _item The URI to the item data.
     */
    function addItem(string calldata _item) external payable;

    /**
     * @notice Gets the arbitratorExtraData for new requests.
     * @dev Gets the latest value in arbitrationParamsChanges.
     * @return The arbitrator extra data.
     */
    function arbitratorExtraData() external view returns (bytes memory);

    function submissionBaseDeposit() external view returns (uint256);

    function getItemInfo(
        bytes32 _itemID
    ) external view returns (uint8 status, uint256 numberOfRequests, uint256 sumDeposit);

    function executeRequest(bytes32 _itemID) external;

    function challengePeriodDuration() external returns (uint256);
}
