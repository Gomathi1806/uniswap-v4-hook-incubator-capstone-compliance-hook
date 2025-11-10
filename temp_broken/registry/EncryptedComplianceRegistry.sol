// src/registry/EncryptedComplianceRegistry.sol
pragma solidity ^0.8.24;

import {FHEOperations} from "../libraries/FHEOperations.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@fhenixprotocol/contracts/FHE.sol";

contract EncryptedComplianceRegistry is Ownable {
    using FHEOperations for *;
    using FHE for *;

    // Mapping from World ID nullifier to encrypted compliance data
    mapping(uint256 => FHEOperations.EncryptedComplianceData)
        private complianceData;

    // Mapping from address to encrypted transaction data
    mapping(address => FHEOperations.EncryptedTransactionData)
        private transactionData;

    // Events
    event ComplianceDataUpdated(uint256 indexed nullifierHash);
    event TransactionProcessed(address indexed user, uint256 timestamp);

    modifier onlyAuthorizedOracle() {
        // Add oracle authorization logic
        _;
    }

    function updateComplianceData(
        uint256 nullifierHash,
        uint32 riskScore,
        uint32 amlStatus,
        bool isBlacklisted
    ) external onlyAuthorizedOracle {
        complianceData[nullifierHash] = FHEOperations.encryptComplianceData(
            riskScore,
            amlStatus,
            uint64(block.timestamp),
            isBlacklisted
        );

        emit ComplianceDataUpdated(nullifierHash);
    }

    function checkCompliance(
        uint256 nullifierHash,
        uint32 minRiskScore,
        uint32 minAmlStatus
    ) external view returns (ebool) {
        return
            complianceData[nullifierHash].checkComplianceThreshold(
                minRiskScore,
                minAmlStatus
            );
    }

    function processTransaction(
        address user,
        uint256 amount,
        uint32 frequencyIncrement
    ) external {
        transactionData[user].updateTransactionMetrics(
            amount,
            frequencyIncrement
        );
        emit TransactionProcessed(user, block.timestamp);
    }

    function getComplianceStatus(
        uint256 nullifierHash
    )
        external
        view
        onlyOwner
        returns (
            uint32 riskScore,
            uint32 amlStatus,
            uint64 lastUpdated,
            bool isBlacklisted
        )
    {
        FHEOperations.EncryptedComplianceData memory data = complianceData[
            nullifierHash
        ];

        // Only owner can decrypt for regulatory reporting
        return (
            FHE.decrypt(data.riskScore),
            FHE.decrypt(data.amlStatus),
            FHE.decrypt(data.lastUpdated),
            FHE.decrypt(data.isBlacklisted)
        );
    }
}
