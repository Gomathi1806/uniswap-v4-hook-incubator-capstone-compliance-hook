// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IOpenComplianceOracle {
    struct RiskData {
        uint256 riskScore; // 0-100 calculated risk score
        bool isHighRisk; // High risk flag
        uint256 transactionCount; // Number of transactions
        uint256 lastUpdated; // Last update timestamp
        uint256 totalVolume; // Total transaction volume
    }

    function getRiskData(
        address wallet
    ) external view returns (RiskData memory);

    function updateRiskData(address wallet, RiskData calldata data) external;

    function calculateRiskScore(address wallet) external view returns (uint256);
}
