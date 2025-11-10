// src/libraries/WorldIDVerifier.sol
pragma solidity ^0.8.24;

import {IWorldID} from "../interfaces/IWorldID.sol";

library WorldIDVerifier {
    error InvalidWorldIDProof();
    error UserAlreadyVerified();
    error InsufficientVerificationLevel();

    struct VerificationData {
        uint256 nullifierHash;
        uint256 timestamp;
        IWorldIDGroups.VerificationLevel level;
        bool isActive;
    }

    function verifyAndStore(
        IWorldID worldID,
        uint256 root,
        uint256 signalHash,
        uint256 nullifierHash,
        uint256 externalNullifierHash,
        uint256[8] calldata proof,
        mapping(uint256 => VerificationData) storage verifications
    ) internal {
        // Verify the World ID proof
        worldID.verifyProof(
            root,
            1, // VerificationLevel.Orb for highest security
            signalHash,
            nullifierHash,
            externalNullifierHash,
            proof
        );

        // Check if user is already verified
        if (verifications[nullifierHash].isActive) {
            revert UserAlreadyVerified();
        }

        // Store verification data
        verifications[nullifierHash] = VerificationData({
            nullifierHash: nullifierHash,
            timestamp: block.timestamp,
            level: IWorldIDGroups.VerificationLevel.Orb,
            isActive: true
        });
    }

    function isVerified(
        uint256 nullifierHash,
        mapping(uint256 => VerificationData) storage verifications
    ) internal view returns (bool) {
        return verifications[nullifierHash].isActive;
    }
}
