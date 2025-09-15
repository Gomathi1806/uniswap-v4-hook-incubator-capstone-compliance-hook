// src/libraries/FHEOperations.sol
pragma solidity ^0.8.24;

// Import Fhenix CoFHE contracts (adjust import paths as needed)
import "@fhenixprotocol/contracts/FHE.sol";

library FHEOperations {
    using FHE for *;

    struct EncryptedComplianceData {
        euint32 riskScore; // Encrypted risk assessment score (0-100)
        euint32 amlStatus; // Encrypted AML clearance status
        euint64 lastUpdated; // Encrypted timestamp of last update
        ebool isBlacklisted; // Encrypted blacklist status
    }

    struct EncryptedTransactionData {
        euint256 amount; // Encrypted transaction amount
        euint32 frequency; // Encrypted transaction frequency score
        ebool flagged; // Encrypted flag for suspicious activity
    }

    function encryptComplianceData(
        uint32 riskScore,
        uint32 amlStatus,
        uint64 lastUpdated,
        bool isBlacklisted
    ) internal pure returns (EncryptedComplianceData memory) {
        return
            EncryptedComplianceData({
                riskScore: FHE.asEuint32(riskScore),
                amlStatus: FHE.asEuint32(amlStatus),
                lastUpdated: FHE.asEuint64(lastUpdated),
                isBlacklisted: FHE.asBool(isBlacklisted)
            });
    }

    function checkComplianceThreshold(
        EncryptedComplianceData memory data,
        uint32 minRiskScore,
        uint32 minAmlStatus
    ) internal view returns (ebool) {
        // Risk score must be below threshold (lower = better)
        ebool riskOk = data.riskScore.lt(FHE.asEuint32(minRiskScore));

        // AML status must meet minimum requirement
        ebool amlOk = data.amlStatus.gte(FHE.asEuint32(minAmlStatus));

        // Must not be blacklisted
        ebool notBlacklisted = data.isBlacklisted.not();

        return riskOk.and(amlOk).and(notBlacklisted);
    }

    function updateTransactionMetrics(
        EncryptedTransactionData storage userData,
        uint256 newAmount,
        uint32 frequencyIncrement
    ) internal {
        userData.amount = userData.amount.add(FHE.asEuint256(newAmount));
        userData.frequency = userData.frequency.add(
            FHE.asEuint32(frequencyIncrement)
        );

        // Flag if transaction amount is unusually high
        uint256 suspiciousThreshold = 100000 * 1e18; // 100k tokens
        userData.flagged = userData.amount.gt(
            FHE.asEuint256(suspiciousThreshold)
        );
    }
}
