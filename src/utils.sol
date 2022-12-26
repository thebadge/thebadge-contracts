// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// TODO: check how it can be marked as challenged. 
// Also how if it was rejected by kleros, can it be marked as Rejected here. 
enum BadgeStatus {
    // The asset has not been created.
    NotCreated,
    // The asset is going through an approval process.
    InReview,
    // The asset was approved.
    Approved,
    // The asset was rejected.
    Rejected,
    // The asset was revoked.
    Revoked
}
